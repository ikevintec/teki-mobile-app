import 'package:teki_app/src/data/models/response/inventory_production_response.dart';

abstract class InventoryProductionRepository {
  Future<InventoryProductionResponse> getProductions(Map<String, dynamic> params);
  Future<void> saveProduction(Map<String, dynamic> production);
  Future<void> voidProduction(int id);
}
