import 'package:teki_app/src/data/models/teki_model/check.dart';
import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/lounge.dart';
import 'package:teki_app/src/data/models/teki_model/order_restaurant.dart';
import 'package:teki_app/src/data/models/teki_model/order_restaurant_change_status_items.dart';
import 'package:teki_app/src/data/models/teki_model/table.dart';

abstract class RestaurantDatasource {
  Future<List<Lounge>> getLounges(Map<String, dynamic> params);
  Future<List<Table>> getTables(Map<String, dynamic> params);
  Future<List<OrderRestaurant>> getOrders(Map<String, dynamic> params);
  Future<OrderRestaurant> createOrder(OrderRestaurant order);
  Future<Command> addCommand(int orderId, Command command);
  Future<List<Check>> saveChecks(int orderId, List<Check> checks);
  Future<void> deleteOrderChecks(int orderId);
  Future<List<OrderRestaurantChangeStatusItems>> updateOrderStatus(int orderId, String estado, {bool updateInventory = true, String? observacion});
  Future<List<Check>> getChecks(Map<String, dynamic> params);
  Future<Check> getCheckById(int id);
  Future<Check> updateCheck(int id, Check check);
  Future<void> updateCommandItemStatus(int commandId, int itemId, String status, {String? motivoAnulacion});
}
