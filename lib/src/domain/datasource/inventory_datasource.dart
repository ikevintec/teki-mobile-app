import 'package:teki_app/src/data/models/response/inventory_record_response.dart';
import 'package:teki_app/src/data/models/response/inventory_response.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';

abstract class InventoryDatasource {
  Future<InventoryResponse> getInventory(Map<String, dynamic> params);
  Future<InventoryRecordResponse> getInventoryLogs(
      int idInventory, Map<String, dynamic> params);

  /// Obtiene el inventario de varios productos en un punto de venta.
  /// Devuelve un mapa `idProducto -> Inventory` para enriquecer listas de
  /// productos que no traen el inventario (ej. búsqueda ligera).
  Future<Map<int, Inventory>> getInventoryByProductIds(
    List<int> productIds, {
    required int idPuntoVenta,
  });
}
