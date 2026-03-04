import 'package:teki_app/src/data/models/response/order_restaurant_response.dart';

abstract class OrdersRestaurantDatasource {
  Future<OrderRestaurantResponse> getOrdersRestaurant(
      Map<String, dynamic> params);
}
