import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/providers/sale/cash_payment_validation.dart';

void main() {
  test('permite vuelto con Yape más efectivo', () {
    expect(validateCashPayment(total: 100, cash: 50, nonCash: 60), isNull);
  });
  test(
    'rechaza sobrepago sin efectivo incluso si hay efectivo en la venta',
    () {
      expect(
        validateCashPayment(total: 100, cash: 50, nonCash: 110),
        isNotNull,
      );
      expect(validateCashPayment(total: 100, cash: 0, nonCash: 110), isNotNull);
    },
  );
  test('rechaza saldo pendiente y admite sumas con residuo binario', () {
    expect(validateCashPayment(total: 100, cash: 30, nonCash: 60), isNotNull);
    expect(
      validateCashPayment(total: 100, cash: 33.33 + 33.33, nonCash: 33.34),
      isNull,
    );
  });
}
