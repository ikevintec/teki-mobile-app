import 'package:teki_app/src/data/datasource/remote_orders_restaurant.dart';
import 'package:teki_app/src/data/models/response/order_restaurant_response.dart';
import 'package:teki_app/src/domain/datasource/orders_restaurant_datasource.dart';
import 'package:teki_app/src/domain/repositories/orders_restaurant_repository.dart';

class OrdersRestaurantRepositoryImpl extends OrdersRestaurantRepository {
  final OrdersRestaurantDatasource datasource;

  OrdersRestaurantRepositoryImpl({OrdersRestaurantDatasource? datasource})
      : datasource = datasource ?? RemoteOrdersRestaurant();

  @override
  Future<OrderRestaurantResponse> getOrdersRestaurant(
      Map<String, dynamic> params) async {
    return datasource.getOrdersRestaurant(params);
  }
}
