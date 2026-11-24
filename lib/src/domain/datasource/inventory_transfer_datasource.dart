import 'package:teki_app/src/data/models/response/inventory_transfer_response.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';
import 'package:teki_app/src/data/models/teki_model/inventory_transfer.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';

abstract class InventoryTransferDatasource {
  Future<InventoryTransferResponse> getTransfers(Map<String, dynamic> params);

  Future<List<Product>> searchProducts(String query);

  Future<Product> getProductById(int id);

  Future<Map<int, Inventory>> getInventoryByProductIds(
    List<int> productIds, {
    required int idPuntoVenta,
  });

  Future<InventoryTransfer> createDirectTransfer(
    DirectInventoryTransferRequest request,
  );
}
