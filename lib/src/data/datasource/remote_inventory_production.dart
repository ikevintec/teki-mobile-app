import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/response/inventory_production_response.dart';
import 'package:teki_app/src/domain/datasource/inventory_production_datasource.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';

class RemoteInventoryProduction extends InventoryProductionDatasource {
  final Dio dio = ApiClient.dio;

  @override
  Future<InventoryProductionResponse> getProductions(
      Map<String, dynamic> params) async {
    try {
      final response =
          await dio.get('/inventory-productions', queryParameters: params);
      return InventoryProductionResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      if (e.response == null) rethrow;
      final resData = e.response?.data;
      final message = (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ?? e.message ?? 'Error de conexión';
      return Future.error('Órdenes de producción: $message');
    } catch (e) {
      return Future.error('Órdenes de producción: ${e.toString()}');
    }
  }

  @override
  Future<void> saveProduction(Map<String, dynamic> production) async {
    try {
      await dio.post('/inventory-productions', data: production);
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      if (e.response == null) rethrow;
      final resData = e.response?.data;
      final message = (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ?? e.message ?? 'Error al registrar la producción';
      return Future.error(message);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  @override
  Future<void> voidProduction(int id) async {
    try {
      await dio.delete('/inventory-productions/$id');
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      if (e.response == null) rethrow;
      final resData = e.response?.data;
      final message = (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ?? e.message ?? 'Error al anular la producción';
      return Future.error(message);
    } catch (e) {
      return Future.error(e.toString());
    }
  }
}
