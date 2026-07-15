import 'package:teki_app/src/data/datasource/remote_inventory.dart';
import 'package:teki_app/src/data/models/response/inventory_record_response.dart';
import 'package:teki_app/src/data/models/response/inventory_response.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';
import 'package:teki_app/src/domain/datasource/inventory_datasource.dart';
import 'package:teki_app/src/domain/repositories/inventory_repository.dart';

class InventoryRepositoryImpl extends InventoryRepository {
  final InventoryDatasource inventoryDatasource;

  InventoryRepositoryImpl({InventoryDatasource? inventoryDatasource})
      : inventoryDatasource = inventoryDatasource ?? RemoteInventory();

  @override
  Future<InventoryResponse> getInventory(Map<String, dynamic> params) async {
    return inventoryDatasource.getInventory(params);
  }

  @override
  Future<InventoryRecordResponse> getInventoryLogs(
      int idInventory, Map<String, dynamic> params) async {
    return inventoryDatasource.getInventoryLogs(idInventory, params);
  }

  @override
  Future<Map<int, Inventory>> getInventoryByProductIds(
    List<int> productIds, {
    required int idPuntoVenta,
  }) async {
    return inventoryDatasource.getInventoryByProductIds(
      productIds,
      idPuntoVenta: idPuntoVenta,
    );
  }
}
