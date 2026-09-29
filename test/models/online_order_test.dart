import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/response/online_order_response.dart';
import 'package:teki_app/src/data/models/teki_model/online_order.dart';

void main() {
  test('OnlineOrder interpreta detalle, opciones y timestamps del backend', () {
    final order = OnlineOrder.fromJson({
      'id': 41,
      'numeroPedido': 123,
      'tipo': 'MENU',
      'estado': 'PENDIENTE',
      'nombreCliente': 'Ana',
      'total': 29.5,
      'createdOn': 1760000000000,
      'ticket': {
        'id': 78,
        'uuid': 'ticket-uuid',
        'identificadorDocumento': 'B001-123',
      },
      'responsable': {'nombreCompleto': 'Luis Pérez'},
      'items': [
        {
          'id': 1,
          'nombreProducto': 'Hamburguesa',
          'cantidad': 2,
          'precioUnitario': 12.5,
          'precioTotal': 25,
          'opciones': [
            {
              'nombreGrupo': 'Salsas',
              'nombreOpcion': 'Mayonesa',
              'cantidad': 1,
            },
          ],
        },
      ],
    });

    expect(order.id, 41);
    expect(order.createdOn, DateTime.fromMillisecondsSinceEpoch(1760000000000));
    expect(order.facturado, isTrue);
    expect(order.comprobante?.id, 78);
    expect(order.comprobante?.uuid, 'ticket-uuid');
    expect(order.comprobante?.identificadorDocumento, 'B001-123');
    expect(order.responsable?.displayName, 'Luis Pérez');
    expect(order.items.single.nombreProducto, 'Hamburguesa');
    expect(order.items.single.opciones.single.nombreOpcion, 'Mayonesa');
  });

  test('OnlineOrder queda como no facturado sin comprobante ni ticket', () {
    final order = OnlineOrder.fromJson({'id': 42, 'estado': 'ATENDIDO'});

    expect(order.facturado, isFalse);
  });

  test('OnlineOrderResponse interpreta la paginación', () {
    final page = OnlineOrderResponse.fromJson({
      'content': [
        {'id': 1, 'estado': 'ACEPTADO'},
      ],
      'number': 2,
      'totalPages': 4,
      'totalElements': 31,
      'first': false,
      'last': false,
    });

    expect(page.content.single.id, 1);
    expect(page.number, 2);
    expect(page.totalElements, 31);
    expect(page.last, isFalse);
  });
}
