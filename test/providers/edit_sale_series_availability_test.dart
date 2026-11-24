import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/batch_product.dart';
import 'package:teki_app/src/data/models/teki_model/batch_product_sale.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/ticket_detail.dart';
import 'package:teki_app/src/providers/sale/products/helpers/edit_sale_series_availability.dart';

void main() {
  group('restoreEditSaleSeriesAvailability', () {
    test('restaura una serie consumida sin mutar el inventario original', () {
      final originalBatch = BatchProduct(
        id: 10,
        tipoLote: 'SERIE',
        serie: 'S-001',
        cantidad: 0,
      );
      final item = _serializedItem(originalBatch);

      final result = restoreEditSaleSeriesAvailability(
        items: [item],
        officeId: 1,
        documentType: 'NV',
      );

      expect(_batch(result.single, 10).cantidad, 1);
      expect(_batch(item, 10).cantidad, 0);
      expect(result.single.lotes?.single.lote?.id, 10);
    });

    test('incorpora una serie original que ya no aparece en el inventario', () {
      final soldBatch = BatchProduct(
        id: 10,
        tipoLote: 'SERIE',
        serie: 'S-001',
        cantidad: 0,
      );
      final item = _serializedItem(soldBatch, inventoryBatches: []);

      final result = restoreEditSaleSeriesAvailability(
        items: [item],
        officeId: 1,
        documentType: '01',
      );

      expect(_batch(result.single, 10).cantidad, 1);
    });

    test('no duplica la disponibilidad si la serie ya tiene saldo', () {
      final soldBatch = BatchProduct(
        id: 10,
        tipoLote: 'SERIE',
        serie: 'S-001',
        cantidad: 1,
      );
      final item = _serializedItem(soldBatch);

      final result = restoreEditSaleSeriesAvailability(
        items: [item],
        officeId: 1,
        documentType: '03',
      );

      expect(_batch(result.single, 10).cantidad, 1);
    });

    test('no altera notas de crédito ni inventarios de otra sede', () {
      final batch = BatchProduct(
        id: 10,
        tipoLote: 'SERIE',
        serie: 'S-001',
        cantidad: 0,
      );
      final item = _serializedItem(batch);

      final creditNote = restoreEditSaleSeriesAvailability(
        items: [item],
        officeId: 1,
        documentType: '07',
      );
      final otherOffice = restoreEditSaleSeriesAvailability(
        items: [item],
        officeId: 2,
        documentType: 'NV',
      );

      expect(identical(creditNote.single, item), isTrue);
      expect(identical(otherOffice.single, item), isTrue);
      expect(_batch(item, 10).cantidad, 0);
    });
  });
}

TicketDetail _serializedItem(
  BatchProduct soldBatch, {
  List<BatchProduct>? inventoryBatches,
}) {
  return TicketDetail(
    cantidad: 1,
    producto: Product(
      id: 20,
      tipoProducto: 'ARTICULO',
      tipoLote: 'SERIE',
      validacionLote: true,
      inventarios: [
        Inventory(
          id: 30,
          puntoVenta: Office(id: 1),
          lotes: inventoryBatches ?? [soldBatch],
        ),
      ],
    ),
    lotes: [BatchProductSale(lote: soldBatch, cantidad: 1)],
  );
}

BatchProduct _batch(TicketDetail item, int id) {
  return item.producto!.inventarios!.single.lotes!.singleWhere(
    (batch) => batch.id == id,
  );
}
