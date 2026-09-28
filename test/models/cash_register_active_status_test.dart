import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/response/cash_register_active_status.dart';

void main() {
  test('parsea el estado liviano de una caja con fecha pasada', () {
    final status = CashRegisterActiveStatus.fromJson({
      'cajaActiva': true,
      'idCaja': 42,
      'fechaCaja': DateTime(2026, 9, 20).millisecondsSinceEpoch,
      'turno': 2,
      'fechaPasada': true,
    });

    expect(status.cajaActiva, isTrue);
    expect(status.idCaja, 42);
    expect(status.fechaCaja, DateTime(2026, 9, 20));
    expect(status.turno, 2);
    expect(status.fechaPasada, isTrue);
  });

  test('acepta la respuesta sin caja activa', () {
    final status = CashRegisterActiveStatus.fromJson({
      'cajaActiva': false,
      'fechaPasada': false,
    });

    expect(status.cajaActiva, isFalse);
    expect(status.fechaCaja, isNull);
    expect(status.fechaPasada, isFalse);
  });
}
