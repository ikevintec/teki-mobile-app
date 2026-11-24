import 'package:teki_app/src/data/models/teki_model/batch_product.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/ticket_detail.dart';

const _inventorySaleDocumentTypes = {'01', '03', 'NV'};
const _seriesProductTypes = {'ARTICULO', 'INSUMO'};

/// Reincorpora, solo en memoria, las series consumidas por la venta que se
/// está editando. El backend revierte el movimiento original antes de aplicar
/// la edición, por lo que esas series también son válidas para el nuevo envío.
///
/// La función no muta el comprobante recibido y no se aplica a cotizaciones ni
/// notas, cuyos movimientos de inventario tienen una semántica diferente.
List<TicketDetail> restoreEditSaleSeriesAvailability({
  required List<TicketDetail> items,
  required int? officeId,
  required String? documentType,
}) {
  if (officeId == null || !_inventorySaleDocumentTypes.contains(documentType)) {
    return items;
  }

  return items.map((item) {
    final product = item.producto;
    if (!_supportsDirectSeries(product)) return item;

    final originalSeries = <int, _OriginalSeries>{};
    for (final saleBatch in item.lotes ?? const []) {
      final batch = saleBatch.lote;
      final id = batch?.id;
      final quantity = saleBatch.cantidad ?? 0;
      if (id == null || batch?.tipoLote != 'SERIE' || quantity <= 0) {
        continue;
      }
      originalSeries.update(
        id,
        (current) => _OriginalSeries(
          batch: current.batch,
          quantity: current.quantity + quantity,
        ),
        ifAbsent: () => _OriginalSeries(batch: batch!, quantity: quantity),
      );
    }
    if (originalSeries.isEmpty) return item;

    var foundOfficeInventory = false;
    final inventories = (product!.inventarios ?? const <Inventory>[]).map((
      inv,
    ) {
      if (inv.puntoVenta?.id != officeId) return inv;
      foundOfficeInventory = true;
      return _restoreInventorySeries(inv, originalSeries);
    }).toList();

    if (!foundOfficeInventory) return item;
    return item.copyWith(producto: product.copyWith(inventarios: inventories));
  }).toList();
}

bool _supportsDirectSeries(Product? product) {
  return product != null &&
      product.tipoLote == 'SERIE' &&
      product.validacionLote == true &&
      _seriesProductTypes.contains(product.tipoProducto);
}

Inventory _restoreInventorySeries(
  Inventory inventory,
  Map<int, _OriginalSeries> originalSeries,
) {
  final restoredIds = <int>{};
  final batches = (inventory.lotes ?? const <BatchProduct>[]).map((batch) {
    final id = batch.id;
    final original = id == null ? null : originalSeries[id];
    if (original == null) return batch;
    restoredIds.add(id!);
    return _copyBatch(
      batch,
      quantity: _effectiveSeriesQuantity(batch.cantidad, original.quantity),
    );
  }).toList();

  for (final entry in originalSeries.entries) {
    if (restoredIds.contains(entry.key)) continue;
    batches.add(
      _copyBatch(
        entry.value.batch,
        quantity: _effectiveSeriesQuantity(0, entry.value.quantity),
      ),
    );
  }

  return Inventory(
    id: inventory.id,
    puntoVenta: inventory.puntoVenta,
    producto: inventory.producto,
    stock: inventory.stock,
    stockAnterior: inventory.stockAnterior,
    usuarioActualizacion: inventory.usuarioActualizacion,
    fechaActualizacion: inventory.fechaActualizacion,
    registros: inventory.registros,
    lotes: batches,
    empresa: inventory.empresa,
  );
}

double _effectiveSeriesQuantity(double? current, double original) {
  return (current ?? 0) + original > 0 ? 1 : 0;
}

BatchProduct _copyBatch(BatchProduct batch, {required double quantity}) {
  return BatchProduct(
    id: batch.id,
    cantidad: quantity,
    cantidadCompra: batch.cantidadCompra,
    tipoLote: batch.tipoLote,
    serie: batch.serie,
    talla: batch.talla,
    color: batch.color,
    fechaFabricacion: batch.fechaFabricacion,
    fechaVencimiento: batch.fechaVencimiento,
    precioCompra: batch.precioCompra,
    modificado: batch.modificado,
    eliminado: batch.eliminado,
    compraLote: batch.compraLote,
    empresa: batch.empresa,
    empresaAdjunta: batch.empresaAdjunta,
    registros: batch.registros,
  );
}

class _OriginalSeries {
  final BatchProduct batch;
  final double quantity;

  const _OriginalSeries({required this.batch, required this.quantity});
}
