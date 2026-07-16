import 'package:teki_app/src/data/models/response/inventory_record_response.dart';
import 'package:teki_app/src/data/models/response/inventory_response.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';

abstract class InventoryRepository {
  Future<InventoryResponse> getInventory(Map<String, dynamic> params);
  Future<InventoryRecordResponse> getInventoryLogs(
      int idInventory, Map<String, dynamic> params);

  /// Obtiene el inventario de varios productos en un punto de venta.
  /// Devuelve un mapa `idProducto -> Inventory`.
  Future<Map<int, Inventory>> getInventoryByProductIds(
    List<int> productIds, {
    required int idPuntoVenta,
  });
}
