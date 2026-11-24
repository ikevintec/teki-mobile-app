import 'dart:math';

import 'package:teki_app/src/data/models/esc_pos/esc_pos_order.dart';
import 'package:teki_app/src/data/models/esc_pos/ticket_print.dart';
import 'package:teki_app/src/data/models/teki_model/printer.dart';

/// Replica la lógica de Angular's invoiceEscPos: convierte TicketPrint
/// en una lista de EscPosOrder aplicando las opciones de la impresora.
/// [esLite] = true genera una versión reducida (sin ítems ni totales detallados).
class InvoiceEscPosFormatter {
  List<Map<String, dynamic>> format(
    TicketPrint data,
    Printer printer, {
    bool esLite = false,
  }) =>
      formatOrders(data, printer, esLite: esLite).map((e) => e.toJson()).toList();

  /// Igual que [format] pero devuelve las órdenes tipadas, para consumidores
  /// locales (impresión BLE) que no necesitan serializar a JSON.
  List<EscPosOrder> formatOrders(
    TicketPrint data,
    Printer printer, {
    bool esLite = false,
  }) {
    final is58mm = printer.anchoPapel == 58;
    final separator = is58mm
        ? '-------------------------------'
        : '------------------------------------------------';
    final headerItems = is58mm
        ? 'PROD.          CANT.  TOT.'
        : 'PRODUCTO             CANT.   P.U.      TOT.';

    final isNotaSunat =
        data.tipoComprobante == '07' || data.tipoComprobante == '08';

    final productLines = esLite ? <EscPosOrder>[] : _buildProductLines(data, is58mm);

    final lines = <EscPosOrder>[
      ..._buildLogoLines(data, printer, esLite),
      ..._buildEmisorLines(data, separator),
      ..._buildComprobanteHeaderLines(data, separator),
      ..._buildFechaClienteLines(data),
      if (isNotaSunat) ..._buildNotaSunatLines(data),
      ..._buildDireccionLines(data),
      ..._buildAdicionalesLines(data),
      if (!esLite) ...[
        EscPosOrder(type: EscPosOrderType.FEED, feed: 1),
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(
            value: headerItems,
            lineBreak: true,
            style: const EscPosStyle(bold: true),
          ),
        ),
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(value: separator, lineBreak: true),
        ),
        ...productLines,
      ],
      EscPosOrder(
        type: EscPosOrderType.TEXT,
        text: EscPosOrderText(value: separator, lineBreak: true),
      ),
      if (!esLite) ..._buildTotalesLines(data),
      ..._buildTotalFinalLines(data),
      ..._buildPropinaLines(data),
      EscPosOrder(
        type: EscPosOrderType.TEXT,
        text: EscPosOrderText(value: separator, lineBreak: true),
      ),
      if (!esLite) ..._buildPaymentLines(data),
      EscPosOrder(type: EscPosOrderType.FEED, feed: 1),
      EscPosOrder(
        type: EscPosOrderType.TEXT,
        text: EscPosOrderText(
          value: 'SON: ${data.montoLetras}',
          lineBreak: true,
          style: const EscPosStyle(justification: 'Center'),
        ),
      ),
      if (data.tipoComprobante != 'NV') ..._buildQrLines(data),
      EscPosOrder(type: EscPosOrderType.FEED, feed: 5),
      if (_shouldOpenDrawer(data, printer))
        const EscPosOrder(type: EscPosOrderType.DRAWER),
    ];

    return lines;
  }

  // ---------------------------------------------------------------------------
  // Secciones de formateo
  // ---------------------------------------------------------------------------

  List<EscPosOrder> _buildLogoLines(TicketPrint data, Printer printer, bool esLite) {
    if (data.logo == null || printer.imprimirLogoTicket != true || esLite) {
      return [];
    }
    return [
      EscPosOrder(
        type: EscPosOrderType.IMAGE,
        image: EscPosOrderImage(url: data.logo, justification: 'Center', width: 200),
      ),
    ];
  }

  List<EscPosOrder> _buildEmisorLines(TicketPrint data, String separator) => [
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(
            value: data.razonSocial,
            lineBreak: true,
            style: const EscPosStyle(justification: 'Center'),
          ),
        ),
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(
            value: data.nombreComercial,
            lineBreak: true,
            style: const EscPosStyle(justification: 'Center', fontSize: '_2'),
          ),
        ),
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(
            value: 'RUC: ${data.rucEmisor}',
            lineBreak: true,
            style: const EscPosStyle(justification: 'Center', bold: true),
          ),
        ),
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(value: 'Dir.: ${data.direccionEmisor}', lineBreak: true),
        ),
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(
            value: 'Teléf.: ${data.telefonoEmisor}   e-mail: ${data.emailEmisor}',
            lineBreak: true,
          ),
        ),
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(value: separator, lineBreak: true),
        ),
      ];

  List<EscPosOrder> _buildComprobanteHeaderLines(TicketPrint data, String separator) => [
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(
            value: data.nombreComprobante,
            lineBreak: true,
            style: const EscPosStyle(justification: 'Center', bold: true),
          ),
        ),
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(
            value: data.serieCorrelativo,
            lineBreak: true,
            style: const EscPosStyle(justification: 'Center', bold: true),
          ),
        ),
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(value: separator, lineBreak: true),
        ),
      ];

  List<EscPosOrder> _buildFechaClienteLines(TicketPrint data) => [
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(
            value: 'Fecha: ',
            lineBreak: false,
            style: const EscPosStyle(bold: true),
          ),
        ),
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(value: data.fechaEmision, lineBreak: true),
        ),
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(
            value: 'Cliente: ',
            lineBreak: false,
            style: const EscPosStyle(bold: true),
          ),
        ),
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(value: data.denominacionReceptor, lineBreak: true),
        ),
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(
            value: data.tipoDocumentoReceptor,
            lineBreak: false,
            style: const EscPosStyle(bold: true),
          ),
        ),
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(value: data.numeroDocumentoReceptor, lineBreak: true),
        ),
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(
            value: 'Moneda: ',
            lineBreak: false,
            style: const EscPosStyle(bold: true),
          ),
        ),
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(value: data.codigoMoneda, lineBreak: true),
        ),
      ];

  List<EscPosOrder> _buildNotaSunatLines(TicketPrint data) => [
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(
            value: 'Comprobante afectado: ',
            lineBreak: false,
            style: const EscPosStyle(bold: true),
          ),
        ),
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(
            value:
                '${data.nombreComprobanteAfectado} ${data.serieAfectado}-${data.numeroAfectado}',
            lineBreak: true,
          ),
        ),
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(
            value: 'Motivo nota: ',
            lineBreak: false,
            style: const EscPosStyle(bold: true),
          ),
        ),
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(value: data.motivoNota, lineBreak: true),
        ),
      ];

  List<EscPosOrder> _buildDireccionLines(TicketPrint data) => [
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(
            value: 'Dirección: ',
            lineBreak: false,
            style: const EscPosStyle(bold: true),
          ),
        ),
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(value: data.direccionReceptor, lineBreak: true),
        ),
      ];

  List<EscPosOrder> _buildAdicionalesLines(TicketPrint data) {
    final lines = <EscPosOrder>[];
    for (final ad in data.adicionales ?? []) {
      lines.add(EscPosOrder(
        type: EscPosOrderType.TEXT,
        text: EscPosOrderText(
          value: '${ad.nombreCampo}: ',
          lineBreak: false,
          style: const EscPosStyle(bold: true),
        ),
      ));
      lines.add(EscPosOrder(
        type: EscPosOrderType.TEXT,
        text: EscPosOrderText(value: ad.valorCampo, lineBreak: true),
      ));
    }
    return lines;
  }

  List<EscPosOrder> _buildProductLines(TicketPrint data, bool is58mm) {
    final widthDes = is58mm ? 14 : 20;
    final lines = <EscPosOrder>[];

    for (final item in data.items ?? []) {
      final descripcion = (item.descripcion ?? '').toUpperCase();
      final chunks = _splitIntoChunks(descripcion, widthDes);

      for (var i = 0; i < chunks.length; i++) {
        final chunk = chunks[i];
        String lineValue;
        if (i == 0) {
          if (is58mm) {
            lineValue =
                '${chunk.padRight(widthDes)}  ${(item.cantidad ?? '').padRight(5)}  ${item.total ?? ''}';
          } else {
            lineValue =
                '${chunk.padRight(widthDes)}  ${(item.cantidad ?? '').padRight(6)}  ${(item.precioUnitario ?? '').padRight(8)}  ${item.total ?? ''}';
          }
        } else {
          lineValue = chunk.padRight(widthDes);
        }
        lines.add(EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(value: lineValue, lineBreak: true),
        ));
      }
    }
    return lines;
  }

  List<EscPosOrder> _buildTotalesLines(TicketPrint data) {
    final sym = data.monedaSimbolo ?? '';
    final lines = <EscPosOrder>[];
    final isNV = data.tipoComprobante == 'NV';

    if (!isNV) {
      lines.addAll(_labelValueRight('OP. GRAVADA: ', '$sym ${data.gravada}'));
    }
    if (_isNonZero(data.exonerada)) {
      lines.addAll(_labelValueRight('OP. EXONERADA: ', '$sym ${data.exonerada}'));
    }
    if (_isNonZero(data.gratuita)) {
      lines.addAll(_labelValueRight('OP. GRATUITA: ', '$sym ${data.gratuita}'));
    }
    if (_isNonZero(data.inafecta)) {
      lines.addAll(_labelValueRight('OP. INAFECTA: ', '$sym ${data.inafecta}'));
    }
    lines.addAll(_labelValueRight('DESCUENTO: ', '$sym ${data.descuento}'));
    if (!isNV) {
      lines.addAll(_labelValueRight('IGV: ', '$sym ${data.igv}'));
    }
    if (_isNonZero(data.isc)) {
      lines.addAll(_labelValueRight('ISC: ', '$sym ${data.isc}'));
    }
    if (_isNonZero(data.tributosBolsas)) {
      lines.addAll(_labelValueRight('ICBP: ', '$sym ${data.tributosBolsas}'));
    }
    if (_isNonZero(data.otrosCargos)) {
      lines.addAll(_labelValueRight('OTROS CARGOS: ', '$sym ${data.otrosCargos}'));
    }
    return lines;
  }

  List<EscPosOrder> _buildTotalFinalLines(TicketPrint data) => [
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(
            value: 'TOTAL: ${data.monedaSimbolo} ${data.totalVenta}',
            lineBreak: true,
            style: const EscPosStyle(bold: true, justification: 'Right'),
          ),
        ),
      ];

  List<EscPosOrder> _buildPropinaLines(TicketPrint data) {
    if (data.propina == null || data.propina!.isEmpty) return [];
    final sym = data.monedaSimbolo ?? '';
    return [
      EscPosOrder(
        type: EscPosOrderType.TEXT,
        text: EscPosOrderText(
          value: 'PROPINA: ',
          lineBreak: false,
          style: const EscPosStyle(bold: true, justification: 'Right'),
        ),
      ),
      EscPosOrder(
        type: EscPosOrderType.TEXT,
        text: EscPosOrderText(
          value: '$sym ${data.propina}',
          lineBreak: true,
          style: const EscPosStyle(justification: 'Right'),
        ),
      ),
      EscPosOrder(
        type: EscPosOrderType.TEXT,
        text: EscPosOrderText(
          value: 'TOTAL CON PROPINA: $sym ${data.totalConPropina}',
          lineBreak: true,
          style: const EscPosStyle(bold: true, justification: 'Right'),
        ),
      ),
    ];
  }

  List<EscPosOrder> _buildPaymentLines(TicketPrint data) {
    final lines = <EscPosOrder>[];

    lines.addAll(_labelValueInline('Vendedor: ', data.vendedor));
    lines.addAll(_labelValueInline('Tipo venta: ', data.tipoVenta));

    if (data.observaciones != null && data.observaciones!.isNotEmpty) {
      lines.addAll(_labelValueInline('Observación: ', data.observaciones));
    }

    lines.add(EscPosOrder(type: EscPosOrderType.FEED, feed: 1));

    for (final fp in data.formasPago ?? []) {
      lines.add(EscPosOrder(
        type: EscPosOrderType.TEXT,
        text: EscPosOrderText(
          value: '${fp.nombre}: ${fp.monto}',
          lineBreak: true,
          style: const EscPosStyle(justification: 'Center', bold: true),
        ),
      ));
    }

    lines.addAll([
      EscPosOrder(
        type: EscPosOrderType.TEXT,
        text: EscPosOrderText(
          value: 'Efectivo: ',
          lineBreak: false,
          style: const EscPosStyle(bold: true, justification: 'Center'),
        ),
      ),
      EscPosOrder(
        type: EscPosOrderType.TEXT,
        text: EscPosOrderText(
          value: data.efectivo,
          lineBreak: true,
          style: const EscPosStyle(justification: 'Center'),
        ),
      ),
      EscPosOrder(
        type: EscPosOrderType.TEXT,
        text: EscPosOrderText(
          value: 'Vuelto: ',
          lineBreak: false,
          style: const EscPosStyle(bold: true, justification: 'Center'),
        ),
      ),
      EscPosOrder(
        type: EscPosOrderType.TEXT,
        text: EscPosOrderText(
          value: data.cambio,
          lineBreak: true,
          style: const EscPosStyle(justification: 'Center'),
        ),
      ),
    ]);

    return lines;
  }

  List<EscPosOrder> _buildQrLines(TicketPrint data) => [
        EscPosOrder(type: EscPosOrderType.FEED, feed: 1),
        EscPosOrder(
          type: EscPosOrderType.QR,
          qr: EscPosOrderQr(justification: 'Center', size: 5, value: data.qr),
        ),
        EscPosOrder(type: EscPosOrderType.FEED, feed: 1),
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(
            value:
                'Representación impresa de la ${data.nombreComprobante}, autorizado mediante resolución N° 0340050001931 - SUNAT. Puede consultar este documento en ${data.urlConsultaComprobante}',
            lineBreak: true,
          ),
        ),
      ];

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool _shouldOpenDrawer(TicketPrint data, Printer printer) {
    if (printer.abrirGaveta != true || data.efectivo == null) return false;
    return (double.tryParse(data.efectivo!) ?? 0) > 0;
  }

  bool _isNonZero(String? value) => value != null && value != '0.00' && value != '0';

  List<EscPosOrder> _labelValueRight(String label, String value) => [
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(
            value: label,
            lineBreak: false,
            style: const EscPosStyle(bold: true, justification: 'Right'),
          ),
        ),
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(
            value: value,
            lineBreak: true,
            style: const EscPosStyle(justification: 'Right'),
          ),
        ),
      ];

  List<EscPosOrder> _labelValueInline(String label, String? value) => [
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(
            value: label,
            lineBreak: false,
            style: const EscPosStyle(bold: true),
          ),
        ),
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(value: value, lineBreak: true),
        ),
      ];

  List<String> _splitIntoChunks(String text, int chunkSize) {
    final result = <String>[];
    for (var i = 0; i < text.length; i += chunkSize) {
      result.add(text.substring(i, min(i + chunkSize, text.length)));
    }
    return result.isEmpty ? [''] : result;
  }
}
