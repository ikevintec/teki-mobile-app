import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:path_provider/path_provider.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/repositories/products_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/products_repository.dart';

/// Nombre del archivo donde se cachea la respuesta plana de productos. Se guarda
/// en el directorio de documentos de la app (no en shared_preferences) porque
/// el JSON puede pesar 4-5MB con ~15-20k productos.
const _cacheFileName = 'flat_products_cache.json';

/// Si la lista supera este umbral, la búsqueda fuzzy se corre en un isolate vía
/// [compute] para no bloquear la UI.
const _computeThreshold = 5000;

/// Máximo de resultados que devuelve una búsqueda local.
const _maxResults = 50;

/// Antigüedad máxima del cache antes de refrescarlo desde el backend.
const _cacheMaxAge = Duration(hours: 12);

final localProductsProvider =
    StateNotifierProvider<LocalProductsNotifier, LocalProductsState>((ref) {
  final ProductsRepository productsRepository = ProductsRepositoryImpl();
  return LocalProductsNotifier(productsRepository: productsRepository);
});

class LocalProductsState {
  /// Todos los productos cargados en memoria para la búsqueda local.
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

  /// Evita disparar varias cargas en paralelo si [ensureLoaded] se llama de
  /// forma concurrente (p.ej. login + apertura de la venta).
  Future<void>? _loadingFuture;

  LocalProductsNotifier({required this.productsRepository})
      : super(const LocalProductsState());

  /// Garantiza que [allProducts] esté disponible en memoria para la búsqueda
  /// local. No bloquea si ya están cargados. La primera vez intenta leer el
  /// cache en disco (rápido) y, si está ausente o vencido, lo trae del backend.
  ///
  /// Es seguro llamarlo de forma asíncrona (fire-and-forget) al iniciar sesión
  /// o al abrir la pantalla de venta: solo la primera invocación hace trabajo.
  Future<void> ensureLoaded({bool forceRefresh = false}) {
    if (state.isLoaded && !forceRefresh) return Future.value();
    return _loadingFuture ??= _load(forceRefresh: forceRefresh)
        .whenComplete(() => _loadingFuture = null);
  }

  Future<void> _load({required bool forceRefresh}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final file = await _cacheFile();
      final cacheExists = await file.exists();

      // Cargar primero desde cache para tener resultados de inmediato.
      if (!forceRefresh && cacheExists) {
        final cached = await _readCache(file);
        if (cached.isNotEmpty) {
          state = state.copyWith(
            allProducts: cached,
            isLoaded: true,
            isLoading: false,
          );
          // Refrescar en segundo plano si el cache está vencido.
          if (await _isStale(file)) {
            unawaited(_fetchAndCache(file));
          }
          return;
        }
      }

      // Sin cache utilizable: traer del backend (esto sí se espera).
      final products = await _fetchAndCache(file);
      state = state.copyWith(
        allProducts: products,
        isLoaded: products.isNotEmpty,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Trae los productos planos del backend, actualiza el cache en disco y el
  /// estado en memoria. Devuelve la lista obtenida.
  Future<List<Product>> _fetchAndCache(File file) async {
    final products = await productsRepository.getFlatProducts();
    if (products.isNotEmpty) {
      await _writeCache(file, products);
      state = state.copyWith(allProducts: products, isLoaded: true);
    }
    return products;
  }

  /// Búsqueda fuzzy sobre los productos cargados en memoria. Pondera `nombre`
  /// (alto), `codigo` y `codigoBarra` (medio). Corre en un isolate cuando la
  /// lista es grande para no trabar la UI.
  Future<List<Product>> searchLocal(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final products = state.allProducts;
    if (products.isEmpty) return [];

    final args = _FuzzySearchArgs(products, q);
    if (products.length > _computeThreshold) {
      return compute(_fuzzySearchProducts, args);
    }
    return _fuzzySearchProducts(args);
  }

  Future<File> _cacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_cacheFileName');
  }

  Future<List<Product>> _readCache(File file) async {
    try {
      final content = await file.readAsString();
      final decoded = jsonDecode(content) as List;
      return decoded
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeCache(File file, List<Product> products) async {
    try {
      final encoded = jsonEncode(products.map((p) => p.toJson()).toList());
      await file.writeAsString(encoded);
    } catch (_) {
      // El cache es best-effort; si falla la escritura seguimos en memoria.
    }
  }

  Future<bool> _isStale(File file) async {
    try {
      final modified = await file.lastModified();
      return DateTime.now().difference(modified) > _cacheMaxAge;
    } catch (_) {
      return true;
    }
  }
}

/// Argumentos serializables para la búsqueda fuzzy en un isolate.
class _FuzzySearchArgs {
  final List<Product> products;
  final String query;
  const _FuzzySearchArgs(this.products, this.query);
}

/// Función top-level (requerida por [compute]) que construye el índice fuzzy y
/// devuelve las coincidencias ordenadas por relevancia.
List<Product> _fuzzySearchProducts(_FuzzySearchArgs args) {
  final options = FuzzyOptions<Product>(
    isCaseSensitive: false,
    threshold: 0.4,
    keys: [
      WeightedKey(name: 'nombre', getter: (p) => p.nombre ?? '', weight: 0.6),
      WeightedKey(name: 'codigo', getter: (p) => p.codigo ?? '', weight: 0.25),
      WeightedKey(
          name: 'codigoBarra',
          getter: (p) => p.codigoBarra ?? '',
          weight: 0.15),
    ],
  );
  final fuse = Fuzzy<Product>(args.products, options: options);
  final results = fuse.search(args.query);
  return results.take(_maxResults).map((r) => r.item).toList();
}
