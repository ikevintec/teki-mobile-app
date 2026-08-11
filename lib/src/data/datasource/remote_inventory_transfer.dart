import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/response/inventory_transfer_response.dart';
import 'package:teki_app/src/data/models/response/product_inventory.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';
import 'package:teki_app/src/data/models/teki_model/inventory_transfer.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/domain/datasource/inventory_transfer_datasource.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';

class RemoteInventoryTransfer extends InventoryTransferDatasource {
  final Dio dio;

  RemoteInventoryTransfer({Dio? dio}) : dio = dio ?? ApiClient.dio;

  @override
  Future<InventoryTransferResponse> getTransfers(
    Map<String, dynamic> params,
  ) async {
    try {
      final response = await dio.get(
        '/inventory-transfers',
        queryParameters: params,
      );
      return InventoryTransferResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw Exception(
        _errorMessage(error, 'No se pudieron cargar los traslados'),
      );
    }
  }

  @override
  Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await dio.get(
        '/products/search',
        queryParameters: {
          'filterGlobal': query,
          'paginacion': false,
          'limit': 20,
          'sortField': 'createdOn',
          'sortOrder': -1,
        },
      );
      return (response.data as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList();
    } on DioException catch (error) {
      throw Exception(_errorMessage(error, 'No se pudieron buscar productos'));
    }
  }

  @override
  Future<Product> getProductById(int id) async {
    try {
      final response = await dio.get('/products/$id');
      return Product.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(_errorMessage(error, 'No se pudo cargar el producto'));
    }
  }

  @override
  Future<Map<int, Inventory>> getInventoryByProductIds(
    List<int> productIds, {
    required int idPuntoVenta,
  }) async {
    if (productIds.isEmpty) return {};
    try {
      final response = await dio.post(
        '/inventory/operations/by-product-ids',
        queryParameters: {'idPuntoVenta': idPuntoVenta},
        data: productIds,
        options: Options(contentType: Headers.jsonContentType),
      );
      final result = <int, Inventory>{};
      for (final item in response.data as List<dynamic>? ?? const []) {
        if (item is! Map<String, dynamic>) continue;
        final parsed = ProductInventory.fromJson(item);
        if (parsed.id != null && parsed.inventario != null) {
          result[parsed.id!] = parsed.inventario!;
        }
      }
      return result;
    } on DioException catch (error) {
      throw Exception(_errorMessage(error, 'No se pudo consultar el stock'));
    }
  }

  @override
  Future<InventoryTransfer> createDirectTransfer(
    DirectInventoryTransferRequest request,
  ) async {
    try {
      final response = await dio.post(
        '/inventory-transfers/direct',
        data: request.toJson(),
        options: Options(contentType: Headers.jsonContentType),
      );
      return InventoryTransfer.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      final fallback = error.response?.statusCode == 412
          ? 'No se pudo realizar el traslado. Verifica el stock disponible.'
          : 'No se pudo realizar el traslado r\u00e1pido';
      throw Exception(_errorMessage(error, fallback));
    }
  }

  String _errorMessage(DioException error, String fallback) {
    if (error.message == 'SESSION_EXPIRED') return 'Sesi\u00f3n expirada';
    if (error.response == null) return 'Sin conexi\u00f3n a internet';
    final data = error.response?.data;
    if (data is Map) {
      final message = data['mensaje'] ?? data['message'] ?? data['error'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }
    if (data is String && data.trim().isNotEmpty) return data;
    return fallback;
  }
}
