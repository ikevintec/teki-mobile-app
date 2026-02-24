import 'package:teki_app/src/data/models/response/inventory_record_response.dart';
import 'package:teki_app/src/data/models/response/inventory_response.dart';

abstract class InventoryDatasource {
  Future<InventoryResponse> getInventory(Map<String, dynamic> params);
  Future<InventoryRecordResponse> getInventoryLogs(
      int idInventory, Map<String, dynamic> params);
}
