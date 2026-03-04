import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/response/order_restaurant_response.dart';
import 'package:teki_app/src/domain/datasource/orders_restaurant_datasource.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import 'package:teki_app/src/utils/notifications.dart';

class RemoteOrdersRestaurant extends OrdersRestaurantDatasource {
  final Dio dio = ApiClient.dio;

  @override
  Future<OrderRestaurantResponse> getOrdersRestaurant(
      Map<String, dynamic> params) async {
    try {
      final response = await dio.get(
        '/orders-restaurant',
        queryParameters: params,
      );
      return OrderRestaurantResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      String errorMessage = 'Error de conexión';
      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? 'Error de conexión';
      } else {
        errorMessage = e.message ?? 'Error de conexión';
      }
      errorNotification(errorMessage);
      return OrderRestaurantResponse.emptyResponse();
    } catch (e) {
      errorNotification(e.toString());
      return OrderRestaurantResponse.emptyResponse();
    }
  }
}
