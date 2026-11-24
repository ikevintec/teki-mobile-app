import 'package:teki_app/src/data/datasource/remote_inventory_sync.dart';
import 'package:teki_app/src/data/models/response/inventory_sync_response.dart';
import 'package:teki_app/src/domain/datasource/inventory_sync_datasource.dart';
import 'package:teki_app/src/domain/repositories/inventory_sync_repository.dart';

class InventorySyncRepositoryImpl implements InventorySyncRepository {
  final InventorySyncDatasource datasource;

  InventorySyncRepositoryImpl({InventorySyncDatasource? datasource})
    : datasource = datasource ?? RemoteInventorySync();

  @override
  Future<InventorySyncSummary> getSummary({
    int? idPuntoVenta,
    String? search,
  }) => datasource.getSummary(idPuntoVenta: idPuntoVenta, search: search);

  @override
  Future<InventorySyncPage> getIssues({
    int? idPuntoVenta,
    String? search,
    required int pageNumber,
    required int perPage,
  }) => datasource.getIssues(
    idPuntoVenta: idPuntoVenta,
    search: search,
    pageNumber: pageNumber,
    perPage: perPage,
  );

  @override
  Future<InventorySyncFixResult> fixIssues(List<int> inventoryIds) =>
      datasource.fixIssues(inventoryIds);
}
