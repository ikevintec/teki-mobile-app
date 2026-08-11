import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/inventory_transfer.dart';

void main() {
  group('DirectInventoryTransferRequest', () {
    test('serializa solo los campos requeridos por el endpoint directo', () {
      const request = DirectInventoryTransferRequest(
        idPuntoVentaOrigen: 10,
        idPuntoVentaDestino: 20,
        comentarioSolicitud: 'Traslado directo',
        items: [
          DirectInventoryTransferItem(idProducto: 100, cantidadSolicitud: 5),
        ],
      );

      expect(request.toJson(), {
        'puntoVentaOrigen': {'id': 10},
        'puntoVentaDestino': {'id': 20},
        'comentarioSolicitud': 'Traslado directo',
        'items': [
          {
            'producto': {'id': 100},
            'cantidadSolicitud': 5.0,
            'lotes': <dynamic>[],
          },
        ],
      });
    });

    test('serializa las series seleccionadas con su cantidad', () {
      const request = DirectInventoryTransferRequest(
        idPuntoVentaOrigen: 10,
        idPuntoVentaDestino: 20,
        comentarioSolicitud: 'Traslado con series',
        items: [
          DirectInventoryTransferItem(
            idProducto: 100,
            cantidadSolicitud: 2,
            lotes: [
              DirectInventoryTransferBatch(idLote: 501),
              DirectInventoryTransferBatch(idLote: 502),
            ],
          ),
        ],
      );

      expect(request.toJson()['items'], [
        {
          'producto': {'id': 100},
          'cantidadSolicitud': 2.0,
          'lotes': [
            {
              'lote': {'id': 501},
              'cantidadSolicitud': 1.0,
            },
            {
              'lote': {'id': 502},
              'cantidadSolicitud': 1.0,
            },
          ],
        },
      ]);
    });
  });

  group('InventoryTransfer', () {
    test('parsea el listado y suma las cantidades solicitadas', () {
      final transfer = InventoryTransfer.fromJson({
        'id': 123,
        'estadoTraslado': 'RECEPCIONADO',
        'puntoVentaOrigen': {'id': 10, 'nombre': 'Origen'},
        'puntoVentaDestino': {'id': 20, 'nombre': 'Destino'},
        'items': [
          {
            'producto': {'id': 100, 'nombre': 'Producto A'},
            'cantidadSolicitud': 5,
            'cantidadAtencion': 5,
            'cantidadRecepcion': 5,
          },
          {
            'producto': {'id': 101, 'nombre': 'Producto B'},
            'cantidadSolicitud': 2.5,
          },
        ],
      });

      expect(transfer.id, 123);
      expect(transfer.estadoTraslado, 'RECEPCIONADO');
      expect(transfer.items, hasLength(2));
      expect(transfer.cantidadSolicitadaTotal, 7.5);
    });
  });
}
