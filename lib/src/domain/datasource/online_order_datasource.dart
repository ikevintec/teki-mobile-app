import 'package:teki_app/src/data/models/response/online_order_response.dart';
import 'package:teki_app/src/data/models/teki_model/online_order.dart';

abstract class OnlineOrderDatasource {
  Future<OnlineOrderResponse> getOrders(Map<String, dynamic> params);
  Future<OnlineOrder> getOrder(int id);
  Future<OnlineOrder> changeStatus(int id, String status);
}
