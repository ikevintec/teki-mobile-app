import 'package:teki_app/src/data/models/response/inventory_adjustment_response.dart';
import 'package:teki_app/src/data/models/teki_model/inventory_adjustment.dart';

abstract class InventoryAdjustmentRepository {
  Future<InventoryAdjustmentResponse> getAdjustments(
      Map<String, dynamic> params);
  Future<InventoryAdjustment> saveAdjustment(InventoryAdjustment adjustment);
}
