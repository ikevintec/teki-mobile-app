import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/providers/sale/credito_cuotas.dart';

void main() {
  group('CreditoCuotas.repartir', () {
    test('100 en 3: las primeras absorben el residuo y la suma es exacta', () {
      final cuotas = CreditoCuotas.repartir(100.0, 3);
      expect(cuotas, [33.34, 33.33, 33.33]);
      expect(cuotas.fold<double>(0, (a, b) => a + b), closeTo(100.0, 0.001));
    });

    test('100 en 6 suma exacta (antes: 16.67×6 = 100.02)', () {
      final cuotas = CreditoCuotas.repartir(100.0, 6);
      expect(cuotas.fold<double>(0, (a, b) => a + b), closeTo(100.0, 0.001));
      expect(cuotas, [16.67, 16.67, 16.67, 16.67, 16.66, 16.66]);
    });

    test('división exacta: todas iguales', () {
      expect(CreditoCuotas.repartir(90.0, 3), [30.0, 30.0, 30.0]);
    });

    test('montos con error binario de double reparten exacto', () {
      // 118.10 - 3.54 = 114.55999999999999 en double
      final cuotas = CreditoCuotas.repartir(118.10 - 3.54, 2);
      expect(cuotas, [57.28, 57.28]);
    });

    test('una sola cuota es el total', () {
      expect(CreditoCuotas.repartir(123.45, 1), [123.45]);
    });

    test('n inválido devuelve vacío', () {
      expect(CreditoCuotas.repartir(100.0, 0), isEmpty);
    });
  });

  group('CreditoCuotas.descuadraTotal (igualdad ±1 centavo, paridad backend)', () {
    test('suma exacta o dentro de 1 centavo NO descuadra', () {
      expect(CreditoCuotas.descuadraTotal([33.34, 33.33, 33.33], 100.0), isFalse);
      expect(CreditoCuotas.descuadraTotal([33.33, 33.33, 33.33], 100.0), isFalse); // 99.99: 1 ctv
      expect(CreditoCuotas.descuadraTotal([50.0, 50.01], 100.0), isFalse); // 100.01: 1 ctv
    });

    test('cuotas que suman de menos se bloquean (antes pasaban)', () {
      expect(CreditoCuotas.descuadraTotal([40.0, 40.0], 100.0), isTrue);
      expect(CreditoCuotas.descuadraTotal([50.0], 100.0), isTrue);
    });

    test('cuotas que exceden el total se bloquean', () {
      expect(CreditoCuotas.descuadraTotal([60.0, 60.0], 100.0), isTrue);
      expect(CreditoCuotas.descuadraTotal([50.0, 50.02], 100.0), isTrue);
    });

    test('sumas con error binario no dan falso positivo', () {
      expect(CreditoCuotas.descuadraTotal([57.28, 57.28], 114.56), isFalse);
    });
  });

  group('CreditoCuotas.round2', () {
    test('redondea a 2 decimales sin colas binarias', () {
      expect(CreditoCuotas.round2(33.333333333333336), 33.33);
      expect(CreditoCuotas.round2(114.55999999999999), 114.56);
      expect(CreditoCuotas.round2(16.665), closeTo(16.67, 0.0001));
    });
  });
}
