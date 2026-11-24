import 'package:teki_app/src/data/models/esc_pos/command_print.dart';
import 'package:teki_app/src/data/models/esc_pos/esc_pos_order.dart';
import 'package:teki_app/src/data/models/teki_model/printer.dart';

/// Replica la lógica de Angular's commandEscPos: convierte CommandPrint
/// en una lista de EscPosOrder aplicando las opciones de la impresora.
class CommandEscPosFormatter {
  List<Map<String, dynamic>> format(CommandPrint data, Printer printer) {
    final separator = (printer.anchoPapel != null && printer.anchoPapel == 58)
        ? '-------------------------------'
        : '------------------------------------------------';

    final productLines = _buildProductLines(data, printer);

    final lines = <EscPosOrder>[
      ..._buildLogoLines(data, printer),
      ..._buildOrderNumberLines(data, printer),
      ..._buildDateLines(data, printer),
      ..._buildFechaAnulacionLines(data),
      ..._buildCamareroLines(data, printer),
      ..._buildClienteLines(data, printer),
      ..._buildMesaLines(data, printer),
      ..._buildSalonLines(data, printer),
      ..._buildAreaLines(data, printer),
      ..._buildAnulacionLines(data),
      EscPosOrder(type: EscPosOrderType.FEED, feed: 1),
      EscPosOrder(
        type: EscPosOrderType.TEXT,
        text: EscPosOrderText(value: separator, lineBreak: true),
      ),
      ...productLines,
      EscPosOrder(
        type: EscPosOrderType.TEXT,
        text: EscPosOrderText(value: separator, lineBreak: true),
      ),
      ..._buildPropinaLines(data),
      EscPosOrder(type: EscPosOrderType.FEED, feed: 5),
    ];

    return lines.map((e) => e.toJson()).toList();
  }

  // ---------------------------------------------------------------------------
  // Secciones de formateo
  // ---------------------------------------------------------------------------

  List<EscPosOrder> _buildLogoLines(CommandPrint data, Printer printer) {
    if (data.logo == null || printer.imprimirLogoTicket != true) return [];
    return [
      EscPosOrder(
        type: EscPosOrderType.IMAGE,
        image: EscPosOrderImage(
          url: data.logo,
          justification: 'Center',
          width: 200,
        ),
      ),
    ];
  }

  List<EscPosOrder> _buildOrderNumberLines(CommandPrint data, Printer printer) {
    if (printer.ocultarNumeroOrden == true) return [];
    return [
      EscPosOrder(
        type: EscPosOrderType.TEXT,
        text: EscPosOrderText(
          value: 'ORDEN ${data.orden}',
          lineBreak: true,
          style: EscPosStyle(
            justification: 'Center',
            bold: true,
            fontSize: printer.fontsizeXNumeroOrden ?? '_1',
            fontSizeX: printer.fontsizeXNumeroOrden ?? '_1',
            fontSizeY: printer.fontsizeYNumeroOrden ?? '_2',
          ),
        ),
      ),
    ];
  }

  List<EscPosOrder> _buildDateLines(CommandPrint data, Printer printer) {
    if (data.anulacion == true || printer.ocultarFecha == true) return [];
    return [
      EscPosOrder(
        type: EscPosOrderType.TEXT,
        text: EscPosOrderText(
          value: 'FECHA: ${data.fecha} - ${data.hora}',
          lineBreak: true,
          style: EscPosStyle(
            bold: true,
            fontSize: printer.fontsizeXFecha ?? '_1',
            fontSizeX: printer.fontsizeXFecha ?? '_1',
            fontSizeY: printer.fontsizeYFecha ?? '_2',
          ),
        ),
      ),
    ];
  }

  List<EscPosOrder> _buildFechaAnulacionLines(CommandPrint data) {
    if (data.fechaAnulacion == null) return [];
    return [
      EscPosOrder(
        type: EscPosOrderType.TEXT,
        text: EscPosOrderText(
          value: 'FECHA ANULACION: ${data.fechaAnulacion}',
          lineBreak: true,
          style: const EscPosStyle(bold: true, fontSizeX: '_1', fontSizeY: '_2'),
        ),
      ),
    ];
  }

  List<EscPosOrder> _buildCamareroLines(CommandPrint data, Printer printer) {
    if (printer.ocultarCamarero == true) return [];
    final style = EscPosStyle(
      bold: true,
      fontSize: printer.fontsizeXCamarero ?? '_1',
      fontSizeX: printer.fontsizeXCamarero ?? '_1',
      fontSizeY: printer.fontsizeYCamarero ?? '_2',
    );
    return [
      EscPosOrder(
        type: EscPosOrderType.TEXT,
        text: EscPosOrderText(value: 'CAMARERO: ', lineBreak: false, style: style),
      ),
      EscPosOrder(
        type: EscPosOrderType.TEXT,
        text: EscPosOrderText(
          value: data.camarero?.toUpperCase(),
          lineBreak: true,
          style: style,
        ),
      ),
    ];
  }

  List<EscPosOrder> _buildClienteLines(CommandPrint data, Printer printer) {
    if (printer.ocultarCliente == true) return [];
    final style = EscPosStyle(
      bold: true,
      fontSize: printer.fontsizeXCliente ?? '_1',
      fontSizeX: printer.fontsizeXCliente ?? '_1',
      fontSizeY: printer.fontsizeYCliente ?? '_2',
    );
    return [
      EscPosOrder(
        type: EscPosOrderType.TEXT,
        text: EscPosOrderText(value: 'CLIENTE: ', lineBreak: false, style: style),
      ),
      EscPosOrder(
        type: EscPosOrderType.TEXT,
        text: EscPosOrderText(value: data.nombreCliente, lineBreak: true, style: style),
      ),
    ];
  }

  List<EscPosOrder> _buildMesaLines(CommandPrint data, Printer printer) {
    if (printer.ocultarMesa == true) return [];
    return [
      EscPosOrder(
        type: EscPosOrderType.TEXT,
        text: EscPosOrderText(
          value: 'MESA: ${data.mesa?.toUpperCase()}',
          lineBreak: true,
          style: EscPosStyle(
            bold: true,
            fontSize: printer.fontsizeXMesa ?? '_1',
            fontSizeX: printer.fontsizeXMesa ?? '_1',
            fontSizeY: printer.fontsizeYMesa ?? '_2',
          ),
        ),
      ),
    ];
  }

  List<EscPosOrder> _buildSalonLines(CommandPrint data, Printer printer) {
    if (printer.ocultarSalon == true) return [];
    return [
      EscPosOrder(
        type: EscPosOrderType.TEXT,
        text: EscPosOrderText(
          value: 'SALON: ${data.salon?.toUpperCase()}',
          lineBreak: true,
          style: EscPosStyle(
            bold: true,
            fontSize: printer.fontsizeXSalon ?? '_1',
            fontSizeX: printer.fontsizeXSalon ?? '_1',
            fontSizeY: printer.fontsizeYSalon ?? '_2',
          ),
        ),
      ),
    ];
  }

  List<EscPosOrder> _buildAreaLines(CommandPrint data, Printer printer) {
    if (printer.ocultarArea == true) return [];
    return [
      EscPosOrder(
        type: EscPosOrderType.TEXT,
        text: EscPosOrderText(
          value: 'AREA: ${data.zona?.toUpperCase()}',
          lineBreak: true,
          style: EscPosStyle(
            bold: true,
            fontSize: printer.fontsizeXArea ?? '_1',
            fontSizeX: printer.fontsizeXArea ?? '_1',
            fontSizeY: printer.fontsizeYArea ?? '_2',
          ),
        ),
      ),
    ];
  }

  List<EscPosOrder> _buildAnulacionLines(CommandPrint data) {
    if (data.anulacion != true) return [];
    return [
      EscPosOrder(type: EscPosOrderType.FEED, feed: 1),
      EscPosOrder(
        type: EscPosOrderType.TEXT,
        text: EscPosOrderText(
          value: 'ANULACION',
          lineBreak: true,
          style: const EscPosStyle(
            bold: true,
            fontSize: '_2',
            justification: 'Center',
            fontSizeX: '_1',
            fontSizeY: '_2',
          ),
        ),
      ),
    ];
  }

  List<EscPosOrder> _buildProductLines(CommandPrint data, Printer printer) {
    if (printer.ocultarItems == true) return [];
    final fontSize = printer.letraGrandeComanda == true ? '_2' : '_1';
    final lines = <EscPosOrder>[];

    for (final item in data.items ?? []) {
      final producto = item.producto?.toUpperCase() ?? '';
      final extras = item.extras?.toUpperCase();

      lines.add(EscPosOrder(
        type: EscPosOrderType.TEXT,
        text: EscPosOrderText(
          value: '${item.cantidad} - $producto',
          lineBreak: true,
          style: EscPosStyle(
            bold: true,
            fontSize: printer.fontsizeXItems ?? fontSize,
            fontSizeX: printer.fontsizeXItems ?? '_1',
            fontSizeY: printer.fontsizeYItems ?? '_2',
          ),
        ),
      ));

      if (data.anulacion == true && item.motivoAnulacion != null) {
        lines.add(EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(
            value: 'Motivo anulación: ${item.motivoAnulacion}',
            lineBreak: true,
            style: EscPosStyle(
              bold: true,
              fontSize: printer.fontsizeXItems ?? fontSize,
              fontSizeX: printer.fontsizeXItems ?? '_1',
              fontSizeY: printer.fontsizeYItems ?? '_2',
            ),
          ),
        ));
      }

      if (extras != null && extras.isNotEmpty) {
        lines.add(EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(
            value: extras,
            lineBreak: true,
            style: EscPosStyle(
              bold: true,
              fontSize: printer.fontsizeXExtras ?? fontSize,
              fontSizeX: printer.fontsizeXExtras ?? '_1',
              fontSizeY: printer.fontsizeYExtras ?? '_2',
            ),
          ),
        ));
      }

      lines.add(EscPosOrder(type: EscPosOrderType.FEED, feed: 1));
    }

    return lines;
  }

  List<EscPosOrder> _buildPropinaLines(CommandPrint data) {
    if (data.propina == null) return [];
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
          value: '${data.propina}',
          lineBreak: true,
          style: const EscPosStyle(justification: 'Right'),
        ),
      ),
      if (data.totalConPropina != null)
        EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(
            value: 'TOTAL CON PROPINA: ${data.totalConPropina}',
            lineBreak: true,
            style: const EscPosStyle(bold: true, justification: 'Right'),
          ),
        ),
      EscPosOrder(type: EscPosOrderType.FEED, feed: 1),
    ];
  }
}