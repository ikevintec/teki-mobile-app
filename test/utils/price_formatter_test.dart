import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/utils/price_formatter.dart';

void main() {
  group('PriceFormatter.formatPrice', () {
    test('null retorna "0"', () {
      expect(PriceFormatter.formatPrice(null), '0');
    });

    test('enteros sin decimales', () {
      expect(PriceFormatter.formatPrice(10.0), '10');
      expect(PriceFormatter.formatPrice(0.0), '0');
    });

    test('decimales sin ceros innecesarios', () {
      expect(PriceFormatter.formatPrice(10.5), '10.5');
      expect(PriceFormatter.formatPrice(10.99), '10.99');
    });
  });

  group('PriceFormatter.parsePrice', () {
    test('null y vacío retornan 0.0', () {
      expect(PriceFormatter.parsePrice(null), 0.0);
      expect(PriceFormatter.parsePrice(''), 0.0);
      expect(PriceFormatter.parsePrice('   '), 0.0);
    });

    test('parsea con espacios alrededor', () {
      expect(PriceFormatter.parsePrice(' 12.50 '), 12.5);
    });

    test('texto inválido retorna 0.0', () {
      expect(PriceFormatter.parsePrice('abc'), 0.0);
    });
  });

  group('PriceFormatter.areSignificantlyDifferent', () {
    test('diferencia mayor a un centavo', () {
      expect(PriceFormatter.areSignificantlyDifferent(10.00, 10.02), isTrue);
    });

    test('diferencia de un centavo o menos no es significativa', () {
      expect(PriceFormatter.areSignificantlyDifferent(10.00, 10.01), isFalse);
      expect(PriceFormatter.areSignificantlyDifferent(10.00, 10.00), isFalse);
    });

    test('null se trata como 0.0', () {
      expect(PriceFormatter.areSignificantlyDifferent(null, 0.005), isFalse);
      expect(PriceFormatter.areSignificantlyDifferent(null, 5.0), isTrue);
    });
  });
}
