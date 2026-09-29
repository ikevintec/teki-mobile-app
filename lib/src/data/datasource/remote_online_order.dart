import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/response/online_order_response.dart';
import 'package:teki_app/src/data/models/teki_model/online_order.dart';
import 'package:teki_app/src/domain/datasource/online_order_datasource.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';

class RemoteOnlineOrder implements OnlineOrderDatasource {
  final Dio dio;

  RemoteOnlineOrder({Dio? dio}) : dio = dio ?? ApiClient.dio;

  @override
  Future<OnlineOrderResponse> getOrders(Map<String, dynamic> params) async {
    try {
      final response = await dio.get(
        '/pedidos-tienda-online',
        queryParameters: params,
      );
      return OnlineOrderResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (error) {
      throw _mapError(error, 'No se pudieron cargar los pedidos online');
    }
  }

  @override
  Future<OnlineOrder> getOrder(int id) async {
    try {
      final response = await dio.get('/pedidos-tienda-online/$id');
      return OnlineOrder.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (error) {
      throw _mapError(error, 'No se pudo cargar el detalle del pedido');
    }
  }

  @override
  Future<OnlineOrder> changeStatus(int id, String status) async {
    try {
      final response = await dio.patch(
        '/pedidos-tienda-online/$id/estado',
        queryParameters: {'estado': status},
        data: const <String, dynamic>{},
      );
      return OnlineOrder.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (error) {
      throw _mapError(error, 'No se pudo actualizar el pedido');
    }
  }

  Exception _mapError(DioException error, String fallback) {
    if (error.message == 'SESSION_EXPIRED') {
      return Exception('Sesión expirada');
    }
    if (error.response == null) return Exception(error.message ?? fallback);
    final data = error.response?.data;
    final message = data is Map
        ? (data['mensaje'] ?? data['message'] ?? data['error'])?.toString()
        : null;
    return Exception(message?.isNotEmpty == true ? message : fallback);
  }
}
