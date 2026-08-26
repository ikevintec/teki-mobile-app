import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/replicador/replicador_app.dart';
import 'package:teki_app/src/shared/services/yape_notification_service.dart';

YapeCapture _capture(
  String text, {
  String title = 'Yape!',
  NotificationAppType typeApp = NotificationAppType.yape,
}) => YapeCapture(
  id: '1',
  title: title,
  text: text,
  bigText: '',
  typeApp: typeApp,
);

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

  test('parsea una notificación Plin de Interbank', () {
    final data = _capture(
      'Luis Alberto Albarran Jara te ha plineado S/ 1.00',
      typeApp: NotificationAppType.interbank,
    ).parse();

    expect(data?.nombrePagador, 'Luis Alberto Albarran Jara');
    expect(data?.monto, 1);
    expect(data?.codigoOperacion, '-');
    expect(data?.tipoApp, NotificationAppType.interbank);
  });

  test('parsea una notificación Plin de BBVA', () {
    final data = _capture(
      'LUIS ALBERTO ALBARRAN te plineó S/1 .',
      typeApp: NotificationAppType.bbva,
    ).parse();

    expect(data?.nombrePagador, 'LUIS ALBERTO ALBARRAN');
    expect(data?.monto, 1);
    expect(data?.codigoOperacion, '-');
    expect(data?.tipoApp, NotificationAppType.bbva);
  });
}
