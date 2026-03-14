import 'package:teki_app/src/data/datasource/remote_restaurant.dart';
import 'package:teki_app/src/data/models/teki_model/check.dart';
import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/lounge.dart';
import 'package:teki_app/src/data/models/teki_model/orderRestaurant.dart';
import 'package:teki_app/src/data/models/teki_model/orderRestaurantChangeStatusItems.dart';
import 'package:teki_app/src/data/models/teki_model/table.dart';
import 'package:teki_app/src/domain/datasource/restaurant_datasource.dart';
import 'package:teki_app/src/domain/repositories/restaurant_repository.dart';

class RestaurantRepositoryImpl extends RestaurantRepository {
  final RestaurantDatasource restaurantDatasource;

  RestaurantRepositoryImpl({RestaurantDatasource? restaurantDatasource})
      : restaurantDatasource = restaurantDatasource ?? RemoteRestaurant();

  @override
  Future<List<Lounge>> getLounges(Map<String, dynamic> params) =>
      restaurantDatasource.getLounges(params);

  @override
  Future<List<Table>> getTables(Map<String, dynamic> params) =>
      restaurantDatasource.getTables(params);

  @override
  Future<List<OrderRestaurant>> getOrders(Map<String, dynamic> params) =>
      restaurantDatasource.getOrders(params);

  @override
  Future<OrderRestaurant> createOrder(OrderRestaurant order) =>
      restaurantDatasource.createOrder(order);

  @override
  Future<Command> addCommand(int orderId, Command command) =>
      restaurantDatasource.addCommand(orderId, command);

  @override
  Future<List<Check>> saveChecks(int orderId, List<Check> checks) =>
      restaurantDatasource.saveChecks(orderId, checks);

  @override
  Future<void> deleteOrderChecks(int orderId) =>
      restaurantDatasource.deleteOrderChecks(orderId);

  @override
  Future<List<OrderRestaurantChangeStatusItems>> updateOrderStatus(int orderId, String estado, {bool updateInventory = true, String? observacion}) =>
      restaurantDatasource.updateOrderStatus(orderId, estado, updateInventory: updateInventory, observacion: observacion);

  @override
  Future<List<Check>> getChecks(Map<String, dynamic> params) =>
      restaurantDatasource.getChecks(params);

  @override
  Future<Check> getCheckById(int id) =>
      restaurantDatasource.getCheckById(id);

  @override
  Future<Check> updateCheck(int id, Check check) =>
      restaurantDatasource.updateCheck(id, check);

  @override
  Future<void> updateCommandItemStatus(int commandId, int itemId, String status) =>
      restaurantDatasource.updateCommandItemStatus(commandId, itemId, status);
}
