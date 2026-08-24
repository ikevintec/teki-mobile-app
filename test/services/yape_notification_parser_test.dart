import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/shared/services/yape_notification_service.dart';

YapeCapture _capture(String text, {String title = 'Yape!'}) =>
    YapeCapture(id: '1', title: title, text: text, bigText: '');

void main() {
  test('parsea el formato real de Yape con código de seguridad', () {
    final data = _capture(
      'Luis Alb* te envió un pago por S/ 1. El cod. de seguridad es: 984',
    ).parse();

    expect(data, isNotNull);
    expect(data!.nombrePagador, 'Luis Alb*');
    expect(data.monto, 1);
    expect(data.codigoOperacion, '984');
  });

  test('parsea montos con decimales y miles', () {
    expect(_capture('Ana te envió un pago por S/ 25,50').parse()!.monto, 25.50);
    expect(
      _capture('Ana te envió un pago por S/ 1,234.50').parse()!.monto,
      1234.50,
    );
  });

  test('devuelve null si no hay monto', () {
    expect(_capture('Bienvenido a Yape').parse(), isNull);
  });
}
