import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/providers/sale/credito_cuotas.dart';

void main() {
  group('CreditoCuotas.repartir', () {
    test('100 en 3: la última absorbe el residuo y la suma es exacta', () {
      final cuotas = CreditoCuotas.repartir(100.0, 3);
      expect(cuotas, [33.33, 33.33, 33.34]);
      expect(cuotas.fold<double>(0, (a, b) => a + b), closeTo(100.0, 0.001));
    });

    test('100 en 6 no sobra (antes: 16.67×6 = 100.02)', () {
      final cuotas = CreditoCuotas.repartir(100.0, 6);
      expect(cuotas.fold<double>(0, (a, b) => a + b), closeTo(100.0, 0.001));
      expect(cuotas.sublist(0, 5), everyElement(16.66));
      expect(cuotas.last, closeTo(16.70, 0.001));
    });

    test('división exacta: todas iguales', () {
      expect(CreditoCuotas.repartir(90.0, 3), [30.0, 30.0, 30.0]);
    });

    test('una sola cuota es el total', () {
      expect(CreditoCuotas.repartir(123.45, 1), [123.45]);
    });

    test('n inválido devuelve vacío', () {
      expect(CreditoCuotas.repartir(100.0, 0), isEmpty);
    });
  });

  group('CreditoCuotas.excedeTotal (paridad validador web totalCuotas)', () {
    test('suma exacta o menor NO excede (la web lo permite)', () {
      expect(CreditoCuotas.excedeTotal([33.33, 33.33, 33.34], 100.0), isFalse);
      expect(CreditoCuotas.excedeTotal([33.33, 33.33, 33.33], 100.0), isFalse);
      expect(CreditoCuotas.excedeTotal([40.0, 40.0], 100.0), isFalse);
    });

    test('cuotas editadas que exceden el total se bloquean', () {
      expect(CreditoCuotas.excedeTotal([60.0, 60.0], 100.0), isTrue);
      expect(CreditoCuotas.excedeTotal([50.0, 50.02], 100.0), isTrue);
    });
  });
}
