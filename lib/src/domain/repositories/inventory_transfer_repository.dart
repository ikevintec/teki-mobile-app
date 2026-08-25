import 'package:teki_app/src/data/models/response/inventory_transfer_response.dart';
import 'package:teki_app/src/data/models/teki_model/inventory_transfer.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';

abstract class InventoryTransferRepository {
  Future<InventoryTransferResponse> getTransfers(Map<String, dynamic> params);

  Future<List<Product>> searchProducts(String query);

  Future<Product> getProductForTransfer({
    required int productId,
    required int idPuntoVentaOrigen,
    required int idPuntoVentaDestino,
  });

  Future<InventoryTransfer> createDirectTransfer(
    DirectInventoryTransferRequest request,
  );
}
