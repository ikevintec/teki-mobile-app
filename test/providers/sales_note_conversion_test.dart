import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/additional_field.dart';
import 'package:teki_app/src/data/models/teki_model/batch_product.dart';
import 'package:teki_app/src/data/models/teki_model/batch_product_sale.dart';
import 'package:teki_app/src/data/models/teki_model/guia_relacionada.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/ticket_detail.dart';
import 'package:teki_app/src/providers/sale/helpers/sales_note_conversion.dart';

void main() {
  group('canConvertSalesNote', () {
    test('solo permite notas vigentes sin comprobante sustituto', () {
      expect(canConvertSalesNote(Ticket(tipoComprobante: 'NV')), isTrue);
      expect(canConvertSalesNote(Ticket(tipoComprobante: '01')), isFalse);
      expect(
        canConvertSalesNote(Ticket(tipoComprobante: 'NV', anulado: true)),
        isFalse,
      );
      expect(
        canConvertSalesNote(
          Ticket(tipoComprobante: 'NV', comprobanteSustituto: 'F001-10'),
        ),
        isFalse,
      );
    });
  });

  group('buildTicketFromSalesNote', () {
    final now = DateTime(2026, 9, 28, 10, 30);

    test('crea una boleta nueva para un receptor con DNI', () {
      final batchSale = BatchProductSale(
        id: 81,
        lote: BatchProduct(id: 17),
        cantidad: 2,
        createdBy: 1,
      );
      final item = TicketDetail(
        id: 45,
        uuid: 'uuid-item-original',
        descripcion: 'Producto',
        cantidad: 2,
        lotes: [batchSale],
        createdBy: 1,
      );
      final field = AditionalField(
        id: 12,
        nombreCampo: 'Mesa',
        valorCampo: '4',
      );
      final guide = GuiaRelacionada(
        id: 13,
        codigoTipoGuia: '09',
        serieNumeroGuia: 'T001-1',
      );
      final source = Ticket(
        id: 99,
        uuid: 'uuid-nota',
        identificadorDocumento: '20123456789-NV01-123',
        serie: 'NV01',
        numero: 123,
        tipoComprobante: 'NV',
        tipoDocumentoReceptor: '1',
        numeroDocumentoReceptor: '12345678',
        codigoMoneda: 'PEN',
        tipoVenta: 'CREDITO',
        diasCredito: 15,
        observacion: 'Observación original',
        otrosCargos: 3,
        otrosTributos: 2,
        porcentajeDescuentoGlobal: 5,
        camposAdicionales: [field],
        items: [item],
        guiasRelacionadas: [guide],
        estadoSunat: 'NO_ENV',
        anulado: false,
      );

      final result = buildTicketFromSalesNote(source: source, now: now);

      expect(result.tipoComprobante, '03');
      expect(result.idNotaVentaAnulada, source.identificadorDocumento);
      expect(result.fechaEmisionDate, now);
      expect(result.codigoMoneda, 'PEN');
      expect(result.tipoVenta, 'CREDITO');
      expect(result.diasCredito, 15);
      expect(result.observacion, 'Observación original');
      expect(result.items, isNot(same(source.items)));
      expect(result.items!.single.id, isNull);
      expect(result.items!.single.uuid, isNull);
      expect(result.items!.single.createdBy, isNull);
      expect(result.items!.single.lotes!.single.id, isNull);
      expect(result.items!.single.lotes!.single.lote!.id, 17);
      expect(result.camposAdicionales, isNot(same(source.camposAdicionales)));
      expect(result.camposAdicionales!.single.id, isNull);
      expect(result.camposAdicionales!.single.nombreCampo, 'Mesa');
      expect(result.guiasRelacionadas!.single.id, isNull);
      expect(result.guiasRelacionadas!.single.serieNumeroGuia, 'T001-1');

      expect(result.id, isNull);
      expect(result.uuid, isNull);
      expect(result.identificadorDocumento, isNull);
      expect(result.serie, isNull);
      expect(result.numero, isNull);
      expect(result.estadoSunat, isNull);
      expect(result.comprobanteSustituto, isNull);
      expect(result.movimientoCaja, isNull);
    });

    test('crea una factura para un receptor distinto de DNI', () {
      final source = Ticket(
        identificadorDocumento: '20123456789-NV01-124',
        tipoComprobante: 'NV',
        tipoDocumentoReceptor: '6',
      );

      final result = buildTicketFromSalesNote(source: source, now: now);

      expect(result.tipoComprobante, '01');
    });

    test('rechaza una nota sin identificador de documento', () {
      final source = Ticket(tipoComprobante: 'NV');

      expect(
        () => buildTicketFromSalesNote(source: source, now: now),
        throwsArgumentError,
      );
    });
  });
}
