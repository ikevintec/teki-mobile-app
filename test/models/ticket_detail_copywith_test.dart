import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/ticket_detail.dart';

void main() {
  group('TicketDetail.copyWith — campos de impuestos aceptan null explícito', () {
    final gravado = TicketDetail(
      descripcion: 'Prod',
      cantidad: 1,
      precioVentaUnitario: 900.0,
      valorUnitario: 762.71,
      valorVenta: 762.71,
      montoBaseIgv: 762.71,
      igv: 137.29,
      porcentajeIgv: 18,
      codigoTipoAfectacionIgv: '10',
    );

    test('regresión SUNAT 3110: al pasar null, el IGV viejo NO debe quedarse', () {
      // Reproduce el cambio gravado → exonerado del calculoTotal.
      final exonerado = gravado.copyWith(
        codigoTipoAfectacionIgv: '20',
        igv: null,
        montoBaseIgv: null,
        porcentajeIgv: null,
      );
      expect(exonerado.igv, isNull,
          reason: 'con el patrón ?? el 137.29 viajaba a SUNAT (rechazo 3110)');
      expect(exonerado.montoBaseIgv, isNull);
      expect(exonerado.porcentajeIgv, isNull);
      expect(exonerado.codigoTipoAfectacionIgv, '20');
    });

    test('omitir el parámetro conserva el valor (comportamiento clásico)', () {
      final copia = gravado.copyWith(descripcion: 'Otro');
      expect(copia.igv, 137.29);
      expect(copia.montoBaseIgv, 762.71);
      expect(copia.porcentajeIgv, 18);
    });

    test('pasar un valor lo actualiza', () {
      final copia = gravado.copyWith(igv: 5.0, montoBaseExonerado: 100.0);
      expect(copia.igv, 5.0);
      expect(copia.montoBaseExonerado, 100.0);
    });

    test('limpieza completa de bases (bloque global del calculoTotal)', () {
      final base = gravado.copyWith(
        montoBaseExonerado: 10.0,
        montoBaseInafecto: 11.0,
        montoBaseGratuito: 12.0,
        montoBaseExportacion: 13.0,
        valorReferencialUnitario: 14.0,
        tributoVentaGratuita: 15.0,
        porcentajeTributoVentaGratuita: 18.0,
      );
      final limpio = base.copyWith(
        montoBaseExonerado: null,
        montoBaseInafecto: null,
        montoBaseGratuito: null,
        montoBaseExportacion: null,
        valorReferencialUnitario: null,
        tributoVentaGratuita: null,
        porcentajeTributoVentaGratuita: null,
      );
      expect(limpio.montoBaseExonerado, isNull);
      expect(limpio.montoBaseInafecto, isNull);
      expect(limpio.montoBaseGratuito, isNull);
      expect(limpio.montoBaseExportacion, isNull);
      expect(limpio.valorReferencialUnitario, isNull);
      expect(limpio.tributoVentaGratuita, isNull);
      expect(limpio.porcentajeTributoVentaGratuita, isNull);
    });
  });
}
