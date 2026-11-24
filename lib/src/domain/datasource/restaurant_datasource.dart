import 'package:teki_app/src/data/models/teki_model/check.dart';
import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/lounge.dart';
import 'package:teki_app/src/data/models/teki_model/order_restaurant.dart';
import 'package:teki_app/src/data/models/teki_model/order_restaurant_change_status_items.dart';
import 'package:teki_app/src/data/models/teki_model/production_area.dart';
import 'package:teki_app/src/data/models/teki_model/table.dart';

abstract class RestaurantDatasource {
  Future<List<Lounge>> getLounges(Map<String, dynamic> params);
  Future<List<Table>> getTables(Map<String, dynamic> params);
  Future<void> attendTableCall(int tableId);
  Future<void> attendTable(int tableId);
  Future<List<OrderRestaurant>> getOrders(Map<String, dynamic> params);
  Future<List<Command>> getCommands(Map<String, dynamic> params);
  Future<List<Command>> getPendingQrCommands(int officeId);
  Future<void> reviewQrCommands(
    List<int> commandIds,
    String status, {
    bool attend = false,
  });
  Future<List<ProductionArea>> getProductionAreas();
  Future<OrderRestaurant> createOrder(OrderRestaurant order);
  Future<Command> addCommand(int orderId, Command command);
  Future<List<Check>> saveChecks(int orderId, List<Check> checks);
  Future<void> deleteOrderChecks(int orderId);
  Future<List<OrderRestaurantChangeStatusItems>> updateOrderStatus(
    int orderId,
    String estado, {
    bool updateInventory = true,
    String? observacion,
  });
  Future<List<Check>> getChecks(Map<String, dynamic> params);
  Future<Check> getCheckById(int id);
  Future<Check> updateCheck(int id, Check check);
  Future<void> updateCommandItemStatus(
    int commandId,
    int itemId,
    String status, {
    String? motivoAnulacion,
    double? cantidad,
  });
  Future<void> updateCommandItemsStatus(
    int commandId,
    List<int> itemIds,
    String status,
  );
  Future<void> expandCommandItem(int itemId);
}
