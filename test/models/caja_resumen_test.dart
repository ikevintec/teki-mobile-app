import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/response/caja_resumen.dart';

void main() {
  final json = {
    'totales': [
      {'moneda': 'PEN', 'totalIngresos': 12500.0, 'totalEgresos': 3200.0, 'neto': 9300.0},
      {'moneda': 'USD', 'totalIngresos': 100.0, 'totalEgresos': 0, 'neto': 100.0},
    ],
    'porConcepto': [
      {'concepto': 'COMPRAS', 'tipo': 'EGRESO', 'moneda': 'PEN', 'monto': 2100.0, 'operaciones': 12},
      {'concepto': 'VENTAS', 'tipo': 'INGRESO', 'moneda': 'PEN', 'monto': 11800.0, 'operaciones': 154},
      {'concepto': 'APERTURA_CAJA', 'tipo': 'INGRESO', 'moneda': 'PEN', 'monto': 500.0, 'operaciones': 22},
      {'concepto': 'PROPINAS', 'tipo': 'INGRESO', 'moneda': 'PEN', 'monto': 300.0, 'operaciones': 21},
    ],
    'porMetodoPago': [
      {
        'metodoPago': 'Efectivo',
        'ingreso': [{'moneda': 'PEN', 'monto': 6300.0}],
        'egreso': [{'moneda': 'PEN', 'monto': 3000.0}],
      },
    ],
    'serie': [
      {'bucket': '2026-07-01', 'moneda': 'PEN', 'ingresos': 420.0, 'egresos': 80.0},
    ],
    'serieBucket': 'DIA',
    'totalCajas': 22,
    'cajasAbiertas': 1,
  };

  group('CajaResumen.fromJson', () {
    final resumen = CajaResumen.fromJson(json);

    test('parsea totales, conceptos, métodos y serie', () {
      expect(resumen.totales, hasLength(2));
      expect(resumen.porConcepto, hasLength(4));
      expect(resumen.porMetodoPago, hasLength(1));
      expect(resumen.serie, hasLength(1));
      expect(resumen.serieBucket, 'DIA');
      expect(resumen.totalCajas, 22);
      expect(resumen.cajasAbiertas, 1);
    });

    test('totalDe encuentra la moneda', () {
      expect(resumen.totalDe('PEN')?.neto, 9300.0);
      expect(resumen.totalDe('EUR'), isNull);
    });

    test('monedas con PEN primero', () {
      expect(resumen.monedas.first, 'PEN');
    });

    test('conceptosDe: rendimiento primero, operativos al final', () {
      final conceptos = resumen.conceptosDe('PEN');
      expect(conceptos.map((c) => c.concepto).toList(),
          ['VENTAS', 'PROPINAS', 'COMPRAS', 'APERTURA_CAJA']);
    });

    test('métodos de pago exponen ganancia por moneda', () {
      final efectivo = resumen.porMetodoPago.first;
      expect(efectivo.gananciaForMoneda('PEN'), 3300.0);
    });
  });

  group('ConceptoResumen', () {
    test('etiquetas legibles', () {
      ConceptoResumen c(String concepto) => ConceptoResumen(
          concepto: concepto, tipo: 'INGRESO', moneda: 'PEN', monto: 0, operaciones: 0);
      expect(c('VENTAS').etiqueta, 'Ventas');
      expect(c('RETIRO_CAJA').etiqueta, 'Retiros de caja');
      expect(c('APERTURA_CAJA').esApertura, isTrue);
      expect(c('APERTURA_CAJA').esOperativo, isTrue);
      expect(c('RETIRO_CAJA').esOperativo, isTrue);
      expect(c('VENTAS').esOperativo, isFalse);
      expect(c('DESCONOCIDO').etiqueta, 'DESCONOCIDO');
    });
  });

  group('CajaResumen vacío', () {
    test('fromJson tolera respuesta sin datos', () {
      final vacio = CajaResumen.fromJson(const {});
      expect(vacio.totales, isEmpty);
      expect(vacio.monedas, isEmpty);
      expect(vacio.totalCajas, 0);
    });
  });
}
