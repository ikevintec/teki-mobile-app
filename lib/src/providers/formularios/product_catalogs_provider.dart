import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/brand.dart';
import 'package:teki_app/src/data/models/teki_model/category.dart' as cat;
import 'package:teki_app/src/utils/api_client.constant.dart';

List<T> _parseList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
  final raw = data is List ? data : (data is Map ? (data['content'] ?? []) : []);
  final result = <T>[];
  for (final e in raw) {
    try {
      result.add(fromJson(e as Map<String, dynamic>));
    } catch (err) {
      debugPrint('catalogo: item omitido por parseo: $err');
    }
  }
  return result;
}

/// Lista de categorías para el selector del formulario de producto.
/// Mismos params que la web (idCategoria=0&paginacion=false).
final categoriasProvider =
    FutureProvider.autoDispose<List<cat.Category>>((ref) async {
  final res = await ApiClient.dio.get('/categories',
      queryParameters: {'idCategoria': '0', 'paginacion': 'false'});
  return _parseList(res.data, cat.Category.fromJson);
});

/// Lista de marcas para el selector del formulario de producto.
final marcasProvider = FutureProvider.autoDispose<List<Brand>>((ref) async {
  final res = await ApiClient.dio.get('/brands');
  return _parseList(res.data, Brand.fromJson);
});
