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
      ..._buildMesaSalonLines(data, printer),
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
            fontSize: printer.fontsizeNumeroOrden ?? '_1',
            fontSizeX: printer.fontsizeXNumeroOrden ?? '_1',
            fontSizeY: printer.fontsizeYNumeroOrden ?? '_1',
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
            fontSize: printer.fontsizeOcultarFecha ?? '_1',
            fontSizeX: printer.fontsizeXOcultarFecha ?? '_1',
            fontSizeY: printer.fontsizeYOcultarFecha ?? '_2',
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
      fontSize: printer.fontsizeOcultarCamarero ?? '_1',
      fontSizeX: printer.fontsizeXOcultarCamarero ?? '_1',
      fontSizeY: printer.fontsizeYOcultarCamarero ?? '_2',
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
      fontSize: printer.fontsizeOcultarCliente ?? '_1',
      fontSizeX: printer.fontsizeXOcultarCliente ?? '_1',
      fontSizeY: printer.fontsizeYOcultarCliente ?? '_2',
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

  List<EscPosOrder> _buildMesaSalonLines(CommandPrint data, Printer printer) {
    final mostrarMesa = printer.ocultarMesa != true;
    final mostrarSalon = printer.ocultarSalon != true;
    if (!mostrarMesa && !mostrarSalon) return [];

    final value = (mostrarMesa ? 'MESA: ${data.mesa?.toUpperCase()}     ' : '') +
        (mostrarSalon ? 'SALON: ${data.salon?.toUpperCase()}' : '');

    return [
      EscPosOrder(
        type: EscPosOrderType.TEXT,
        text: EscPosOrderText(
          value: value,
          lineBreak: true,
          style: EscPosStyle(
            bold: true,
            fontSize: printer.fontsizeOcultarSalon ?? '_1',
            fontSizeX: printer.fontsizeXOcultarSalon ?? '_1',
            fontSizeY: printer.fontsizeYOcultarSalon ?? '_2',
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
            fontSize: printer.fontsizeOcultarArea ?? '_2',
            fontSizeX: printer.fontsizeXOcultarArea ?? '_1',
            fontSizeY: printer.fontsizeYOcultarArea ?? '_2',
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
            fontSize: printer.fontsizeOcultarItems ?? fontSize,
            fontSizeX: printer.fontsizeXOcultarItems ?? '_1',
            fontSizeY: printer.fontsizeYOcultarItems ?? '_2',
          ),
        ),
      ));

      if (extras != null && extras.isNotEmpty) {
        lines.add(EscPosOrder(
          type: EscPosOrderType.TEXT,
          text: EscPosOrderText(
            value: extras,
            lineBreak: true,
            style: EscPosStyle(bold: true, fontSize: fontSize, fontSizeX: '_1', fontSizeY: '_2'),
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
