import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/repositories/company_repository_impl.dart';
import 'package:teki_app/src/data/repositories/products_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/company_repository.dart';
import 'package:teki_app/src/domain/repositories/products_repository.dart';
import 'package:teki_app/src/providers/sale/products/helpers/product_local_search.dart';
import 'package:teki_app/src/providers/sale/products/helpers/product_search_worker.dart';

/// El JSON puede pesar 4-5MB con ~20k productos, por eso va a un archivo en el
/// directorio de documentos y no a shared_preferences.
const _cacheFileName = 'flat_products_cache.json';
const _cacheTimestampKey = 'flat_products_cache_timestamp';

/// Cada cuánto se compara el timestamp local con el de Company para detectar
/// cambios hechos desde otro dispositivo.
const _syncInterval = Duration(minutes: 3);

final localProductsProvider =
    StateNotifierProvider<LocalProductsNotifier, LocalProductsState>((ref) {
  final ProductsRepository productsRepository = ProductsRepositoryImpl();
  final CompanyRepository companyRepository = CompanyRepositoryImpl();
  return LocalProductsNotifier(
    productsRepository: productsRepository,
    companyRepository: companyRepository,
  );
});

class LocalProductsState {
  final List<Product> allProducts;
  final bool isLoading;
  final bool isLoaded;
  final String? error;

  const LocalProductsState({
    this.allProducts = const [],
    this.isLoading = false,
    this.isLoaded = false,
    this.error,
  });

  LocalProductsState copyWith({
    List<Product>? allProducts,
    bool? isLoading,
    bool? isLoaded,
    String? error,
  }) {
    return LocalProductsState(
      allProducts: allProducts ?? this.allProducts,
      isLoading: isLoading ?? this.isLoading,
      isLoaded: isLoaded ?? this.isLoaded,
      error: error,
    );
  }
}

class LocalProductsNotifier extends StateNotifier<LocalProductsState>
    with WidgetsBindingObserver {
  final ProductsRepository productsRepository;
  final CompanyRepository companyRepository;

  /// Alineado por posición con [LocalProductsState.allProducts].
  List<ProductSearchEntry> _index = const [];

  final ProductSearchWorker _worker = ProductSearchWorker();

  /// Evita cargas en paralelo si se llama de forma concurrente (p.ej. login +
  /// apertura de la venta).
  Future<void>? _loadingFuture;

  Timer? _syncTimer;
  Future<void>? _syncFuture;
  bool _syncEnabled = false;

  /// Se incrementa al limpiar el cache o parar la sincronización, para que el
  /// trabajo async que quedó en vuelo no vuelva a publicar estado viejo.
  int _generation = 0;

  LocalProductsNotifier({
    required this.productsRepository,
    required this.companyRepository,
  }) : super(const LocalProductsState());

  @override
  void dispose() {
    _stopSync();
    _worker.shutdown();
    super.dispose();
  }

  /// Deja los productos disponibles en memoria, descargándolos si el timestamp
  /// local no coincide con el de Company. No usar desde pantallas: esta ruta
  /// puede pegarle al backend.
  /// [knownTimestamp] evita volver a pedir el timestamp cuando el llamador ya lo
  /// consultó.
  Future<void> ensureLoaded({
    bool forceRefresh = false,
    String? knownTimestamp,
  }) {
    if (state.isLoaded && !forceRefresh) return Future.value();
    return _loadingFuture ??= _load(
      forceRefresh: forceRefresh,
      knownTimestamp: knownTimestamp,
    ).whenComplete(() => _loadingFuture = null);
  }

  /// Flujo de login: inicializa el timestamp, descarga o refresca el JSON y
  /// arranca la sincronización periódica.
  Future<void> prepareCacheForLocalSearch() async {
    final generation = _generation;
    final timestamp = await _ensureTimestampInitialized();
    await ensureLoaded(knownTimestamp: timestamp);
    if (generation == _generation && state.isLoaded) _startSync();
  }

  /// Flujo de pantallas: solo lee el archivo ya descargado. Si no existe, la
  /// búsqueda cae al endpoint online.
  Future<void> ensureCacheLoaded() {
    if (state.isLoaded) return Future.value();
    return _loadingFuture ??=
        _loadCacheOnly().whenComplete(() => _loadingFuture = null);
  }

  /// Devuelve el timestamp del backend para que [ensureLoaded] no lo vuelva a
  /// pedir. Devuelve `null` si Company todavía no tenía uno: ahí conviene que
  /// [_load] lo consulte de nuevo y reintente el push si este falló.
  Future<String?> _ensureTimestampInitialized() async {
    try {
      final backendTimestamp = await _getBackendTimestamp();
      if (backendTimestamp != null) {
        final localTimestamp = await _getLocalTimestamp();
        if (localTimestamp == null) {
          await _saveLocalTimestamp(backendTimestamp);
        }
        return backendTimestamp;
      }

      final timestamp = DateTime.now().toUtc().toIso8601String();
      await _saveLocalTimestamp(timestamp);
      await _updateTimestampInBackend(timestamp);
      return null;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Borra todo lo de la búsqueda local: timer, isolate, índice, JSON en disco,
  /// timestamp y productos en memoria. Se llama en el logout.
  Future<void> clearCache() async {
    _generation++;
    _stopSync();
    _worker.shutdown();
    _index = const [];
    try {
      final file = await _cacheFile();
      if (await file.exists()) {
        await file.delete();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheTimestampKey);
    } catch (_) {
      // Limpiar el cache en el logout es best-effort.
    } finally {
      state = const LocalProductsState();
    }
  }

  /// Refleja en el cache el producto recién creado o editado sin volver a bajar
  /// el JSON completo, y mueve el timestamp para que el resto de dispositivos sí
  /// lo vuelva a bajar.
  Future<void> upsertProductInCache(Product product) async {
    final id = product.id;
    if (id == null) return;

    final generation = _generation;
    final loadingFuture = _loadingFuture;
    if (loadingFuture != null) {
      await loadingFuture;
    }

    final file = await _cacheFile();
    final raw = await _readCacheFile(file);
    final timestamp = DateTime.now().toUtc().toIso8601String();

    // Sin cache completo no se escribe un archivo parcial: solo se mueven los
    // timestamps para forzar la descarga completa la próxima vez.
    if (raw != null) {
      try {
        final data = await compute(
          _upsertIntoCache,
          _UpsertArgs(raw: raw, id: id, product: product.toJson()),
        );
        await file.writeAsString(data.json);
        _applyCache(data, generation);
      } catch (e) {
        state = state.copyWith(error: e.toString());
      }
    }

    await _saveLocalTimestamp(timestamp);
    await _updateTimestampInBackend(timestamp);
  }

  Future<List<Product>> searchLocal(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final products = state.allProducts;
    final index = _index;
    if (products.isEmpty || index.isEmpty) return [];

    final positions = await _worker.search(q) ?? runProductSearch(index, q);

    return [
      for (final position in positions)
        if (position >= 0 && position < products.length) products[position],
    ];
  }

  Product? findByBarcode(String barcode) {
    final q = barcode.trim().toLowerCase();
    if (q.isEmpty) return null;

    final products = state.allProducts;
    for (final entry in _index) {
      if ((entry.codigoBarra == q || entry.codigo == q) &&
          entry.position < products.length) {
        return products[entry.position];
      }
    }
    return null;
  }

  // --- Sincronización periódica -------------------------------------------

  /// El timer solo corre con la app en primer plano: en background no tiene
  /// sentido gastar red, y al volver se chequea de una sin esperar el intervalo.
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (!_syncEnabled) return;
    if (lifecycle == AppLifecycleState.resumed) {
      _resumeTimer();
      _syncNow();
    } else {
      _syncTimer?.cancel();
      _syncTimer = null;
    }
  }

  void _startSync() {
    if (_syncEnabled) return;
    _syncEnabled = true;
    WidgetsBinding.instance.addObserver(this);
    _resumeTimer();
  }

  void _stopSync() {
    if (!_syncEnabled) return;
    _syncEnabled = false;
    _generation++;
    _syncTimer?.cancel();
    _syncTimer = null;
    _syncFuture = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  void _resumeTimer() {
    _syncTimer ??= Timer.periodic(_syncInterval, (_) => _syncNow());
  }

  void _syncNow() {
    if (!_syncEnabled || _syncFuture != null) return;
    final generation = _generation;
    _syncFuture = _refreshIfTimestampChanged(generation).catchError((e) {
      if (generation == _generation) state = state.copyWith(error: e.toString());
    }).whenComplete(() {
      if (generation == _generation) _syncFuture = null;
    });
  }

  /// Solo compara timestamps: la descarga se delega a [ensureLoaded] para no
  /// duplicar el camino de fetch + cache.
  Future<void> _refreshIfTimestampChanged(int generation) async {
    final loadingFuture = _loadingFuture;
    if (loadingFuture != null) await loadingFuture;
    if (generation != _generation) return;

    final backendTimestamp = await _getBackendTimestamp();
    if (generation != _generation || backendTimestamp == null) return;

    final localTimestamp = await _getLocalTimestamp();
    if (generation != _generation || backendTimestamp == localTimestamp) return;

    await ensureLoaded(forceRefresh: true, knownTimestamp: backendTimestamp);
  }

  // --- Carga y cache -------------------------------------------------------

  Future<void> _load({
    required bool forceRefresh,
    String? knownTimestamp,
  }) async {
    final generation = _generation;
    state = state.copyWith(isLoading: true, error: null);
    final file = await _cacheFile();
    try {
      final backendTimestamp = knownTimestamp ?? await _getBackendTimestamp();
      final localTimestamp = await _getLocalTimestamp();

      if (!forceRefresh &&
          backendTimestamp != null &&
          backendTimestamp == localTimestamp &&
          await _loadFromCacheFile(file, generation)) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final timestamp =
          backendTimestamp ?? DateTime.now().toUtc().toIso8601String();
      await _fetchAndCache(
        file,
        timestamp: timestamp,
        generation: generation,
        updateBackendTimestamp: backendTimestamp == null,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      // Ante cualquier fallo se intenta seguir con lo que haya en disco.
      if (!state.isLoaded) await _loadFromCacheFile(file, generation);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _loadCacheOnly() async {
    final generation = _generation;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final file = await _cacheFile();
      final loaded = await _loadFromCacheFile(file, generation);
      state = state.copyWith(
        isLoading: false,
        error: loaded || !await file.exists()
            ? null
            : 'No se pudo leer el cache local de productos',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Guarda el JSON crudo tal cual llega: evita re-serializar 20k productos y
  /// deja el cache idéntico a la respuesta del backend.
  Future<void> _fetchAndCache(
    File file, {
    required String timestamp,
    required int generation,
    required bool updateBackendTimestamp,
  }) async {
    final raw = await productsRepository.getFlatProductsRaw();
    if (generation != _generation) return;
    final data = await compute(_parseCache, raw);

    try {
      await file.writeAsString(raw);
    } catch (_) {
      // El cache en disco es best-effort; si falla seguimos en memoria.
    }
    if (!_applyCache(data, generation)) return;
    await _saveLocalTimestamp(timestamp);

    if (updateBackendTimestamp) {
      await _updateTimestampInBackend(timestamp);
    }
  }

  /// `false` si el archivo no existe o está corrupto, sin tocar lo que ya haya
  /// en memoria.
  Future<bool> _loadFromCacheFile(File file, int generation) async {
    final raw = await _readCacheFile(file);
    if (raw == null) return false;
    try {
      return _applyCache(await compute(_parseCache, raw), generation);
    } catch (_) {
      return false;
    }
  }

  Future<String?> _readCacheFile(File file) async {
    try {
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  /// `false` si mientras tanto se limpió el cache (logout): en ese caso no se
  /// publica nada.
  bool _applyCache(_CacheData data, int generation) {
    if (generation != _generation) return false;
    _index = data.index;
    state = state.copyWith(
      allProducts: data.products,
      isLoaded: true,
      error: null,
    );
    _worker.setIndex(data.index);
    return true;
  }

  Future<File> _cacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_cacheFileName');
  }

  Future<String?> _getBackendTimestamp() async {
    final company = await companyRepository.getCurrentCompanyLocalProducts();
    final timestamp = company.lastUpdateLocalProducts?.trim();
    if (timestamp == null || timestamp.isEmpty) return null;
    return timestamp;
  }

  Future<String?> _getLocalTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_cacheTimestampKey)?.trim();
    if (timestamp == null || timestamp.isEmpty) return null;
    return timestamp;
  }

  Future<void> _saveLocalTimestamp(String timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheTimestampKey, timestamp);
  }

  Future<void> _updateTimestampInBackend(String timestamp) async {
    try {
      await companyRepository.updateLocalTimestamp(timestamp);
    } catch (_) {
      // Cache local funcional; se reintenta si backend sigue sin timestamp.
    }
  }
}

/// `compute` devuelve el resultado con `Isolate.exit`, así que las listas viajan
/// sin copiarse.
class _CacheData {
  final String json;
  final List<Product> products;
  final List<ProductSearchEntry> index;
  const _CacheData({
    required this.json,
    required this.products,
    required this.index,
  });
}

class _UpsertArgs {
  final String raw;
  final int id;
  final Map<String, dynamic> product;
  const _UpsertArgs({
    required this.raw,
    required this.id,
    required this.product,
  });
}

_CacheData _parseCache(String raw) {
  return _buildCacheData(raw, jsonDecode(raw) as List);
}

/// Solo el producto modificado pasa por `toJson()`; el resto conserva el mapa
/// original del backend, así el cache no se degrada con cada edición.
_CacheData _upsertIntoCache(_UpsertArgs args) {
  final decoded = jsonDecode(args.raw) as List;
  final position = decoded.indexWhere(
    (element) => element is Map && element['id'] == args.id,
  );
  if (position == -1) {
    decoded.add(args.product);
  } else {
    decoded[position] = args.product;
  }
  return _buildCacheData(jsonEncode(decoded), decoded);
}

_CacheData _buildCacheData(String json, List<dynamic> decoded) {
  final products = [
    for (final element in decoded)
      Product.fromJson(Map<String, dynamic>.from(element as Map)),
  ];
  return _CacheData(
    json: json,
    products: products,
    index: buildProductSearchIndex(products),
  );
}
