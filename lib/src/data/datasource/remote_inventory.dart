import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/response/inventory_record_response.dart';
import 'package:teki_app/src/data/models/response/inventory_response.dart';
import 'package:teki_app/src/data/models/response/product_inventory.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';
import 'package:teki_app/src/domain/datasource/inventory_datasource.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import 'package:teki_app/src/utils/notifications.dart';

class RemoteInventory extends InventoryDatasource {
  Dio dio = ApiClient.dio;

  @override
  Future<InventoryResponse> getInventory(Map<String, dynamic> params) async {
    try {
      final response =
          await dio.get('/inventory', queryParameters: params);
      return InventoryResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      if (e.response == null) rethrow;
      final resData = e.response?.data;
      final errorMessage = (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ?? e.message ?? 'Error de conexión';
      errorNotification(errorMessage);
      return InventoryResponse(
        content: [],
        empty: true,
        first: true,
        last: false,
        number: 0,
        size: 0,
        totalElements: 0,
        totalPages: 0,
        sort: null,
        pageable: null,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<InventoryRecordResponse> getInventoryLogs(
      int idInventory, Map<String, dynamic> params) async {
    try {
      final response = await dio.get(
        '/inventory/$idInventory',
        queryParameters: params,
      );
      return InventoryRecordResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      final resData = e.response?.data;
      final errorMessage = (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ?? e.message ?? 'Error de conexión';
      errorNotification(errorMessage);
      return InventoryRecordResponse(
        content: [],
        empty: true,
        first: true,
        last: false,
        number: 0,
        size: 0,
        totalElements: 0,
        totalPages: 0,
        sort: null,
        pageable: null,
      );
    } catch (e) {
      errorNotification(e.toString());
      return InventoryRecordResponse(
        content: [],
        empty: true,
        first: true,
        last: false,
        number: 0,
        size: 0,
        totalElements: 0,
        totalPages: 0,
        sort: null,
        pageable: null,
      );
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
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );
      final data = response.data;
      final list = data is List ? data : const [];
      final result = <int, Inventory>{};
      for (final item in list) {
        final parsed = ProductInventory.fromJson(item);
        if (parsed.id != null && parsed.inventario != null) {
          result[parsed.id!] = parsed.inventario!;
        }
      }
      return result;
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      // El enriquecimiento es opcional: ante un error no rompemos la búsqueda.
      return {};
    } catch (_) {
      return {};
    }
  }
}
