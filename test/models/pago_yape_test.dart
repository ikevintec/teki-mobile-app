import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/replicador/replicador_app.dart';
import 'package:teki_app/src/data/models/yape/pago_yape.dart';

void main() {
  test('PagoYapePage interpreta la respuesta paginada del backend', () {
    final page = PagoYapePage.fromJson({
      'content': [
        {
          'id': 7,
          'nombrePagador': 'Ana Torres',
          'monto': 25.5,
          'codigoOperacion': 'YAPE-007',
          'tipoApp': 'YAPE',
          'fechaRegistro': 1724457600000,
          'validado': false,
        },
      ],
      'number': 0,
      'totalPages': 2,
      'totalElements': 21,
      'last': false,
      'first': true,
    });

    expect(page.content, hasLength(1));
    expect(page.content.single.nombrePagador, 'Ana Torres');
    expect(page.content.single.monto, 25.5);
    expect(page.content.single.codigoOperacion, 'YAPE-007');
    expect(page.content.single.tipoApp, NotificationAppType.yape);
    expect(page.content.single.fechaRegistro, isNotNull);
    expect(page.totalElements, 21);
    expect(page.last, isFalse);
  });

  test('PagoYape acepta montos serializados como texto', () {
    final payment = PagoYape.fromJson({
      'nombrePagador': 'Luis',
      'monto': '10.75',
      'codigoOperacion': 'ABC',
    });

    expect(payment.monto, 10.75);
    expect(payment.validado, isFalse);
  });
}
