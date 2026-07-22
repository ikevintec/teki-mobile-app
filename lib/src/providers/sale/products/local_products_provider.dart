import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
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

class LocalProductsNotifier extends StateNotifier<LocalProductsState> {
  final ProductsRepository productsRepository;
  final CompanyRepository companyRepository;

  /// Alineado por posición con [LocalProductsState.allProducts].
  List<ProductSearchEntry> _index = const [];

  final ProductSearchWorker _worker = ProductSearchWorker();

  /// Evita cargas en paralelo si se llama de forma concurrente (p.ej. login +
  /// apertura de la venta).
  Future<void>? _loadingFuture;

  LocalProductsNotifier({
    required this.productsRepository,
    required this.companyRepository,
  }) : super(const LocalProductsState());

  @override
  void dispose() {
    _worker.shutdown();
    super.dispose();
  }

  /// Deja los productos disponibles en memoria, descargándolos si el timestamp
  /// local no coincide con el de Company. No usar desde pantallas: esta ruta
  /// puede pegarle al backend.
  Future<void> ensureLoaded({bool forceRefresh = false}) {
    if (state.isLoaded && !forceRefresh) return Future.value();
    return _loadingFuture ??= _load(forceRefresh: forceRefresh)
        .whenComplete(() => _loadingFuture = null);
  }

  /// Flujo de login: inicializa el timestamp y descarga o refresca el JSON.
  Future<void> prepareCacheForLocalSearch() async {
    await ensureTimestampInitialized();
    await ensureLoaded();
  }

  /// Flujo de pantallas: solo lee el archivo ya descargado. Si no existe, la
  /// búsqueda cae al endpoint online.
  Future<void> ensureCacheLoaded() {
    if (state.isLoaded) return Future.value();
    return _loadingFuture ??=
        _loadCacheOnly().whenComplete(() => _loadingFuture = null);
  }

  Future<void> ensureTimestampInitialized() async {
    try {
      final backendTimestamp = await _getBackendTimestamp();
      if (backendTimestamp != null) {
        final localTimestamp = await _getLocalTimestamp();
        if (localTimestamp == null) {
          await _saveLocalTimestamp(backendTimestamp);
        }
        return;
      }

      final timestamp = DateTime.now().toUtc().toIso8601String();
      await _saveLocalTimestamp(timestamp);
      await _updateTimestampInBackend(timestamp);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> clearCache() async {
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
      _index = const [];
      _worker.shutdown();
      state = const LocalProductsState();
    }
  }

  /// Refleja en el cache el producto recién creado o editado sin volver a bajar
  /// el JSON completo, y mueve el timestamp para que el resto de dispositivos sí
  /// lo vuelva a bajar.
  Future<void> upsertProductInCache(Product product) async {
    final id = product.id;
    if (id == null) return;

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
        _applyCache(data);
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

  Future<void> _load({required bool forceRefresh}) async {
    state = state.copyWith(isLoading: true, error: null);
    final file = await _cacheFile();
    try {
      final backendTimestamp = await _getBackendTimestamp();
      final localTimestamp = await _getLocalTimestamp();

      if (!forceRefresh &&
          backendTimestamp != null &&
          backendTimestamp == localTimestamp &&
          await _loadFromCacheFile(file)) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final timestamp =
          backendTimestamp ?? DateTime.now().toUtc().toIso8601String();
      await _fetchAndCache(
        file,
        timestamp: timestamp,
        updateBackendTimestamp: backendTimestamp == null,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      // Ante cualquier fallo se intenta seguir con lo que haya en disco.
      if (!state.isLoaded) await _loadFromCacheFile(file);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _loadCacheOnly() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final file = await _cacheFile();
      final loaded = await _loadFromCacheFile(file);
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
    required bool updateBackendTimestamp,
  }) async {
    final raw = await productsRepository.getFlatProductsRaw();
    final data = await compute(_parseCache, raw);

    try {
      await file.writeAsString(raw);
    } catch (_) {
      // El cache en disco es best-effort; si falla seguimos en memoria.
    }
    _applyCache(data);
    await _saveLocalTimestamp(timestamp);

    if (updateBackendTimestamp) {
      await _updateTimestampInBackend(timestamp);
    }
  }

  /// `false` si el archivo no existe o está corrupto, sin tocar lo que ya haya
  /// en memoria.
  Future<bool> _loadFromCacheFile(File file) async {
    final raw = await _readCacheFile(file);
    if (raw == null) return false;
    try {
      _applyCache(await compute(_parseCache, raw));
      return true;
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

  void _applyCache(_CacheData data) {
    _index = data.index;
    state = state.copyWith(
      allProducts: data.products,
      isLoaded: true,
      error: null,
    );
    _worker.setIndex(data.index);
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
