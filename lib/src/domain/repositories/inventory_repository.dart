import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/response/inventory_detail_page.dart';
import 'package:teki_app/src/data/models/teki_model/batch_product.dart';
import 'package:teki_app/src/data/models/teki_model/inventory_record.dart';
import 'package:teki_app/src/data/models/response/inventory_record_response.dart';
import 'package:teki_app/src/data/models/response/inventory_response.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';

abstract class InventoryRepository {
  Future<InventoryResponse> getInventory(Map<String, dynamic> params);
  Future<InventoryRecordResponse> getInventoryLogs(
    int idInventory,
    Map<String, dynamic> params,
  );

  Future<InventoryDetailPage<BatchProduct>> getInventoryBatches(
    int idInventory,
    int pageNumber,
    int perPage, {
    CancelToken? cancelToken,
  });

  Future<InventoryDetailPage<InventoryRecord>> getBatchRecords(
    int idBatch,
    int pageNumber,
    int perPage, {
    CancelToken? cancelToken,
  });

  /// Obtiene el inventario de varios productos en un punto de venta.
  /// Devuelve un mapa `idProducto -> Inventory`.
  Future<Map<int, Inventory>> getInventoryByProductIds(
    List<int> productIds, {
    required int idPuntoVenta,
  });
}
