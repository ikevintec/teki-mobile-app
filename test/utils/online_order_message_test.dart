import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/online_order.dart';
import 'package:teki_app/src/utils/online_order_message.dart';

void main() {
  test('construye mensaje predeterminado de aceptación', () {
    const order = OnlineOrder(
      id: 9,
      numeroPedido: 25,
      tipo: 'MENU',
      nombreCliente: 'Rosa',
    );

    final message = buildOnlineOrderStatusMessage(
      order,
      'ACEPTADO',
      'Teki Café',
    );

    expect(message, contains('Hola Rosa, le saludamos de Teki Café'));
    expect(message, contains('#00000025'));
    expect(message, contains('ha sido aceptado'));
  });

  test('reemplaza las variables de la plantilla de anulación', () {
    const order = OnlineOrder(
      id: 9,
      numeroPedido: 25,
      nombreCliente: 'Rosa',
      mensajeRechazoPedido:
          '{{nombreEmpresa}}: pedido {{numeroPedido}} de {{nombreCliente}} anulado',
    );

    final message = buildOnlineOrderStatusMessage(
      order,
      'ANULADO',
      'Teki Café',
    );

    expect(message, 'Teki Café: pedido 00000025 de Rosa anulado');
  });
}
