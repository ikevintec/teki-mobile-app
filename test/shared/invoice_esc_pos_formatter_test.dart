import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/esc_pos/ticket_print.dart';
import 'package:teki_app/src/data/models/teki_model/printer.dart';
import 'package:teki_app/src/shared/services/invoice_esc_pos_formatter.dart';

/// Extrae los valores de texto de la salida del formatter (lista de JSON).
List<String> textValues(List<Map<String, dynamic>> orders) => orders
    .map((o) => (o['text'] as Map<String, dynamic>?)?['value'] as String?)
    .whereType<String>()
    .toList();

void main() {
  final formatter = InvoiceEscPosFormatter();

  TicketPrint buildBoleta({
    String tipoComprobante = '03',
    String? efectivo,
    String? exonerada,
    String? propina,
  }) {
    return TicketPrint(
      razonSocial: 'MI EMPRESA SAC',
      nombreComercial: 'Mi Tienda',
      rucEmisor: '20123456789',
      direccionEmisor: 'Av. Principal 123',
      tipoComprobante: tipoComprobante,
      nombreComprobante: 'BOLETA DE VENTA ELECTRONICA',
      serieCorrelativo: 'B001-00000042',
      fechaEmision: '21/07/2026',
      monedaSimbolo: 'S/.',
      montoLetras: 'CIEN CON 00/100 SOLES',
      gravada: '84.75',
      exonerada: exonerada ?? '0.00',
      descuento: '0.00',
      igv: '15.25',
      totalVenta: '100.00',
      efectivo: efectivo,
      propina: propina,
      qr: 'QR-DATA',
      urlConsultaComprobante: 'https://consulta.teki.pe',
      items: [
        TicketItemPrint(
          descripcion: 'producto uno',
          cantidad: '2',
          precioUnitario: '25.00',
          total: '50.00',
        ),
      ],
    );
  }

  group('InvoiceEscPosFormatter', () {
    test('boleta básica incluye emisor, comprobante, items, totales y QR', () {
      final out = formatter.format(buildBoleta(), Printer());
      final texts = textValues(out);

      expect(texts, contains('MI EMPRESA SAC'));
      expect(texts, contains('RUC: 20123456789'));
      expect(texts.any((t) => t.contains('B001-00000042')), isTrue);
      expect(texts.any((t) => t.startsWith('PRODUCTO UNO')), isTrue,
          reason: 'la descripción del item va en mayúsculas');
      expect(texts, contains('OP. GRAVADA: '));
      expect(texts, contains('IGV: '));
      expect(texts, contains('TOTAL: S/. 100.00'));
      expect(texts, contains('SON: CIEN CON 00/100 SOLES'));
      expect(out.any((o) => o.containsKey('qr')), isTrue);
    });

    test('nota de venta (NV) no lleva QR, ni gravada, ni IGV', () {
      final out = formatter.format(buildBoleta(tipoComprobante: 'NV'), Printer());
      final texts = textValues(out);

      expect(out.any((o) => o.containsKey('qr')), isFalse);
      expect(texts, isNot(contains('OP. GRAVADA: ')));
      expect(texts, isNot(contains('IGV: ')));
      expect(texts, contains('TOTAL: S/. 100.00'));
    });

    test('esLite omite items y totales intermedios pero mantiene el total', () {
      final out = formatter.format(buildBoleta(), Printer(), esLite: true);
      final texts = textValues(out);

      expect(texts.any((t) => t.startsWith('PRODUCTO UNO')), isFalse);
      expect(texts, isNot(contains('OP. GRAVADA: ')));
      expect(texts, contains('TOTAL: S/. 100.00'));
    });

    test('totales condicionales solo aparecen cuando son distintos de cero', () {
      final sinExonerada = textValues(formatter.format(buildBoleta(), Printer()));
      expect(sinExonerada, isNot(contains('OP. EXONERADA: ')));

      final conExonerada = textValues(
          formatter.format(buildBoleta(exonerada: '10.00'), Printer()));
      expect(conExonerada, contains('OP. EXONERADA: '));
    });

    test('columnas de items según ancho de papel', () {
      final out58 =
          textValues(formatter.format(buildBoleta(), Printer(anchoPapel: 58)));
      final out80 =
          textValues(formatter.format(buildBoleta(), Printer(anchoPapel: 80)));

      expect(out58, contains('PROD.          CANT.  TOT.'));
      expect(out80, contains('PRODUCTO             CANT.   P.U.      TOT.'));
      // En 58mm no se imprime el precio unitario en la línea del item
      final item58 = out58.firstWhere((t) => t.startsWith('PRODUCTO UNO'));
      expect(item58.contains('25.00'), isFalse);
      final item80 = out80.firstWhere((t) => t.startsWith('PRODUCTO UNO'));
      expect(item80.contains('25.00'), isTrue);
    });

    test('gaveta se abre solo con permiso de impresora y pago en efectivo', () {
      bool hasDrawer(List<Map<String, dynamic>> out) =>
          out.any((o) => o['type'] == 'DRAWER');

      // Sin permiso de la impresora
      expect(
          hasDrawer(formatter.format(buildBoleta(efectivo: '50.00'), Printer())),
          isFalse);
      // Con permiso pero sin efectivo
      expect(
          hasDrawer(formatter.format(
              buildBoleta(), Printer(abrirGaveta: true))),
          isFalse);
      // Con permiso y efectivo
      expect(
          hasDrawer(formatter.format(
              buildBoleta(efectivo: '50.00'), Printer(abrirGaveta: true))),
          isTrue);
    });

    test('propina se imprime solo cuando existe', () {
      final sinPropina = textValues(formatter.format(buildBoleta(), Printer()));
      expect(sinPropina.any((t) => t.startsWith('PROPINA')), isFalse);

      final conPropina = textValues(
          formatter.format(buildBoleta(propina: '5.00'), Printer()));
      expect(conPropina, contains('PROPINA: '));
    });
  });
}
