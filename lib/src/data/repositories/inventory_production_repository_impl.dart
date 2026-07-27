import 'package:teki_app/src/data/datasource/remote_inventory_production.dart';
import 'package:teki_app/src/data/models/response/inventory_production_response.dart';
import 'package:teki_app/src/domain/datasource/inventory_production_datasource.dart';
import 'package:teki_app/src/domain/repositories/inventory_production_repository.dart';

class InventoryProductionRepositoryImpl extends InventoryProductionRepository {
  final InventoryProductionDatasource datasource;

  InventoryProductionRepositoryImpl({InventoryProductionDatasource? datasource})
      : datasource = datasource ?? RemoteInventoryProduction();

  @override
  Future<InventoryProductionResponse> getProductions(
          Map<String, dynamic> params) =>
      datasource.getProductions(params);

  @override
  Future<void> saveProduction(Map<String, dynamic> production) =>
      datasource.saveProduction(production);

  @override
  Future<void> voidProduction(int id) => datasource.voidProduction(id);
}
