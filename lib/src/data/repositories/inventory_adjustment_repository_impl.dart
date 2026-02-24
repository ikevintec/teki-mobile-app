import 'package:teki_app/src/data/datasource/remote_inventory_adjustment.dart';
import 'package:teki_app/src/data/models/response/inventory_adjustment_response.dart';
import 'package:teki_app/src/data/models/teki_model/inventory_adjustment.dart';
import 'package:teki_app/src/domain/datasource/inventory_adjustment_datasource.dart';
import 'package:teki_app/src/domain/repositories/inventory_adjustment_repository.dart';

class InventoryAdjustmentRepositoryImpl extends InventoryAdjustmentRepository {
  final InventoryAdjustmentDatasource adjustmentDatasource;

  InventoryAdjustmentRepositoryImpl(
      {InventoryAdjustmentDatasource? adjustmentDatasource})
      : adjustmentDatasource =
            adjustmentDatasource ?? RemoteInventoryAdjustment();

  @override
  Future<InventoryAdjustmentResponse> getAdjustments(
      Map<String, dynamic> params) async {
    return adjustmentDatasource.getAdjustments(params);
  }

  @override
  Future<InventoryAdjustment> saveAdjustment(
      InventoryAdjustment adjustment) async {
    return adjustmentDatasource.saveAdjustment(adjustment);
  }
}
