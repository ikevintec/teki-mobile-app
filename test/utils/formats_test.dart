import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/utils/formats.dart';

void main() {
  group('parseDateTimeFlexible', () {
    test('null retorna null', () {
      expect(parseDateTimeFlexible(null), isNull);
    });

    test('int se interpreta como timestamp en milisegundos', () {
      final dt = parseDateTimeFlexible(1700000000000);
      expect(dt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
    });

    test('string ISO-8601 válido se parsea', () {
      expect(
        parseDateTimeFlexible('2026-07-21T10:30:00'),
        DateTime(2026, 7, 21, 10, 30),
      );
    });

    test('string inválido retorna null', () {
      expect(parseDateTimeFlexible('no-es-fecha'), isNull);
    });

    test('tipos no soportados retornan null', () {
      expect(parseDateTimeFlexible(3.14), isNull);
    });
  });

  group('normalizeEnumLabel', () {
    test('reemplaza guiones bajos por espacios', () {
      expect(normalizeEnumLabel('PEDIDO_ONLINE'), 'PEDIDO ONLINE');
    });

    test('null y vacío retornan guion', () {
      expect(normalizeEnumLabel(null), '-');
      expect(normalizeEnumLabel(''), '-');
    });

    test('texto sin guiones bajos queda igual', () {
      expect(normalizeEnumLabel('DELIVERY'), 'DELIVERY');
    });
  });

  group('formatOrderNumber', () {
    test('rellena con ceros a 8 dígitos', () {
      expect(formatOrderNumber(123), '00000123');
    });

    test('null retorna guion', () {
      expect(formatOrderNumber(null), '-');
    });

    test('números de más de 8 dígitos no se truncan', () {
      expect(formatOrderNumber(123456789), '123456789');
    });
  });

  group('formatDouble', () {
    test('entero sin decimales', () {
      expect(formatDouble(7.0), '7');
    });

    test('decimales a dos posiciones', () {
      expect(formatDouble(7.25), '7.25');
      expect(formatDouble(7.256), '7.26');
    });
  });

  group('formatExchange', () {
    test('monedas conocidas', () {
      expect(formatExchange(moneda: 'PEN'), 'S/. ');
      expect(formatExchange(moneda: 'USD'), '\$ ');
      expect(formatExchange(moneda: 'EUR'), '€ ');
    });

    test('moneda desconocida retorna el código', () {
      expect(formatExchange(moneda: 'MXN'), 'MXN');
    });
  });

  group('formatEstadoSunat', () {
    test('estados conocidos', () {
      expect(formatEstadoSunat('ACEPT'), 'Aceptado');
      expect(formatEstadoSunat('RECHA'), 'Rechazado');
      expect(formatEstadoSunat('ANULA'), 'Anulado');
      expect(formatEstadoSunat('N_ENV'), 'No enviado');
    });

    test('null o desconocido retorna guion', () {
      expect(formatEstadoSunat(null), '-');
      expect(formatEstadoSunat('OTRO'), '-');
    });
  });
}
