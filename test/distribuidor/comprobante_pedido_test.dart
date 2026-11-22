import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/domain/distribuidor/comprobante_pedido.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/quotation.dart';

void main() {
  Map<String, dynamic> pedido(String destino, String tipo, String numero) => {
    'tipoComprobanteDestino': destino,
    'codigoMoneda': 'PEN',
    'totalVenta': 80,
    'cliente': <String, dynamic>{
      'tipoDocumento': tipo,
      'numeroDocumento': numero,
      'razonSocial': 'Cliente QA',
    },
  };
  test('factura requiere RUC válido y boleta conserva DNI o RUC', () {
    expect(
      validarComprobantePedido(pedido('01', '1', '12345678')),
      contains('RUC'),
    );
    expect(
      validarComprobantePedido(pedido('01', '6', '20100070971')),
      contains('válido'),
    );
    expect(validarComprobantePedido(pedido('01', '6', '20100070970')), isNull);
    expect(validarComprobantePedido(pedido('03', '1', '12345678')), isNull);
    expect(validarComprobantePedido(pedido('03', '6', '20100070970')), isNull);
    expect(validarComprobantePedido(pedido('NV', '1', '12345678')), isNull);
    expect(
      validarComprobantePedido(pedido('03', '1', '1234')),
      contains('8 dígitos'),
    );
  });
  test(
    'boleta desde 700 identifica cliente; no calcula umbral desde etiqueta',
    () {
      final p = pedido('03', '1', '00000000');
      (p['cliente'] as Map)['porDefecto'] = true;
      p['totalVenta'] = 700;
      expect(validarComprobantePedido(p), contains('700'));
      p['totalVenta'] = 699.99;
      expect(validarComprobantePedido(p), isNull);
      p['tipoComprobanteDestino'] = null;
      expect(validarComprobantePedido(p), contains('Selecciona'));
    },
  );
  test(
    'ticket, borrador y conversión mantienen destino; cotizaciones conservan boleta inicial',
    () {
      final q = Quotation.fromJson({
        'id': 5,
        'isQuotation': false,
        'tipoComprobanteDestino': 'NV',
        'items': [],
      });
      expect(q.toTicketForSale().tipoComprobante, 'NV');
      final t = Ticket.fromJson(q.toTicketForEdit().toJson());
      expect(t.tipoComprobanteDestino, 'NV');
      expect(t.copyWith(observacion: 'Cambio').tipoComprobanteDestino, 'NV');
      expect(Quotation.fromJson(q.toJson()).tipoComprobanteDestino, 'NV');
      expect(
        Quotation.fromJson({
          'id': 6,
          'isQuotation': true,
          'items': [],
        }).toTicketForSale().tipoComprobante,
        '03',
      );
    },
  );
}
