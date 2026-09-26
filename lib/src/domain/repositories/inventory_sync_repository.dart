import 'package:teki_app/src/data/models/response/inventory_sync_response.dart';

abstract class InventorySyncRepository {
  Future<InventorySyncSummary> getSummary({int? idPuntoVenta, String? search});

  Future<InventorySyncPage> getIssues({
    int? idPuntoVenta,
    String? search,
    required int pageNumber,
    required int perPage,
  });

  Future<InventorySyncFixResult> fixIssues(List<int> inventoryIds);
}
