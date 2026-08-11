import 'package:teki_app/src/data/datasource/remote_inventory_transfer.dart';
import 'package:teki_app/src/data/models/response/inventory_transfer_response.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';
import 'package:teki_app/src/data/models/teki_model/inventory_transfer.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/domain/datasource/inventory_transfer_datasource.dart';
import 'package:teki_app/src/domain/repositories/inventory_transfer_repository.dart';

class InventoryTransferRepositoryImpl extends InventoryTransferRepository {
  final InventoryTransferDatasource datasource;

  InventoryTransferRepositoryImpl({InventoryTransferDatasource? datasource})
    : datasource = datasource ?? RemoteInventoryTransfer();

  @override
  Future<InventoryTransferResponse> getTransfers(Map<String, dynamic> params) =>
      datasource.getTransfers(params);

  @override
  Future<List<Product>> searchProducts(String query) =>
      datasource.searchProducts(query);

  @override
  Future<Product> getProductForTransfer({
    required int productId,
    required int idPuntoVentaOrigen,
    required int idPuntoVentaDestino,
  }) async {
    final responses = await Future.wait<dynamic>([
      datasource.getProductById(productId),
      datasource.getInventoryByProductIds([
        productId,
      ], idPuntoVenta: idPuntoVentaOrigen),
      datasource.getInventoryByProductIds([
        productId,
      ], idPuntoVenta: idPuntoVentaDestino),
    ]);

    final product = responses[0] as Product;
    final originInventory = (responses[1] as Map<int, Inventory>)[productId];
    final destinationInventory =
        (responses[2] as Map<int, Inventory>)[productId];

    final inventoriesByOffice = <int, Inventory>{};
    for (final inventory in product.inventarios ?? const <Inventory>[]) {
      final officeId = inventory.puntoVenta?.id;
      if (officeId != null) inventoriesByOffice[officeId] = inventory;
    }
    if (originInventory != null) {
      inventoriesByOffice[idPuntoVentaOrigen] = _withOffice(
        originInventory,
        idPuntoVentaOrigen,
      );
    }
    if (destinationInventory != null) {
      inventoriesByOffice[idPuntoVentaDestino] = _withOffice(
        destinationInventory,
        idPuntoVentaDestino,
      );
    }

    return product.copyWith(inventarios: inventoriesByOffice.values.toList());
  }

  Inventory _withOffice(Inventory inventory, int officeId) {
    if (inventory.puntoVenta?.id != null) return inventory;
    return Inventory(
      id: inventory.id,
      puntoVenta: Office(id: officeId),
      producto: inventory.producto,
      stock: inventory.stock,
      stockAnterior: inventory.stockAnterior,
      usuarioActualizacion: inventory.usuarioActualizacion,
      fechaActualizacion: inventory.fechaActualizacion,
      registros: inventory.registros,
      lotes: inventory.lotes,
      empresa: inventory.empresa,
    );
  }

  @override
  Future<InventoryTransfer> createDirectTransfer(
    DirectInventoryTransferRequest request,
  ) => datasource.createDirectTransfer(request);
}
