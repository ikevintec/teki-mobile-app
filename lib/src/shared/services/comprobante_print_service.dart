import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/esc_pos/ticket_print.dart';
import 'package:teki_app/src/data/models/teki_model/config.dart';
import 'package:teki_app/src/data/models/teki_model/printer.dart';
import 'package:teki_app/src/shared/services/invoice_esc_pos_formatter.dart';
import 'package:teki_app/src/shared/services/print_coffe_service.dart';
import 'package:teki_app/src/shared/services/printer/esc_pos_generator_service.dart';
import 'package:teki_app/src/shared/services/printer/printer_service.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';

class ComprobantePrintService {
  final Dio _dio = ApiClient.dio;
  final PrintCoffeService _printCoffeService = PrintCoffeService();
  final InvoiceEscPosFormatter _formatter = InvoiceEscPosFormatter();
  final EscPosGeneratorService _escPosGenerator = EscPosGeneratorService();

  /// Imprime un comprobante vía Coffe (ESC/POS o PDF) y devuelve el resultado
  /// reportado por el servicio (Coffe responde 200 aunque no haya impreso).
  /// [esLite] = true genera la versión reducida (boleta lite).
  /// Lanza [PrintCoffeException] si el servicio de impresión falla.
  Future<PrintCoffeResult> printComprobante({
    required int ticketId,
    required String pdfUrl,
    required Printer printer,
    required bool escPos,
    required String officeCode,
    required int? idCompany,
    bool esLite = false,
  }) async {
    final printerOfficeCode =
        '$officeCode${printer.codigoCoffe != null ? '_${printer.codigoCoffe}' : ''}';

    if (escPos) {
      final ticketPrint = await _fetchTicketPrint(ticketId);
      if (ticketPrint == null) {
        return PrintCoffeResult(
          printed: false,
          message: 'No se pudo obtener los datos del comprobante para imprimir.',
        );
      }

      final orders = _formatter.format(ticketPrint, printer, esLite: esLite);
      return _printCoffeService.printCoffe({
        'printerName': printer.nombre,
        'orders': orders,
        'event': 'printEscPos',
        'idCompany': idCompany,
        'officeCode': printerOfficeCode,
      });
    } else {
      return _printCoffeService.printCoffe({
        'url': pdfUrl,
        'scale': printer.coffeEscala ?? 2.5,
        'printerName': printer.nombre,
        'event': 'printPdf',
        'idCompany': idCompany,
        'officeCode': printerOfficeCode,
      });
    }
  }

  /// Imprime un comprobante en una impresora térmica BLE local, generando el
  /// ESC/POS en la app a partir del MISMO formateador de órdenes que usa
  /// Coffe. Se usa cuando la empresa tiene tipoImpresionMovil = BLUETOOTH_BLE.
  /// Lanza [PrinterException] si el transporte BLE falla.
  Future<PrintCoffeResult> printComprobanteBle({
    required int ticketId,
    required PrinterService printerService,
    required PrinterDevice blePrinter,
    bool esLite = false,
  }) async {
    final ticketPrint = await _fetchTicketPrint(ticketId);
    if (ticketPrint == null) {
      return PrintCoffeResult(
        printed: false,
        message: 'No se pudo obtener los datos del comprobante para imprimir.',
      );
    }

    // Configuración sintética de impresora para el formateador: por BLE no
    // hay logo (imágenes deshabilitadas en la v1) ni gaveta.
    final printerConfig = Printer(
      anchoPapel: blePrinter.paperWidthMm,
      imprimirLogoTicket: false,
      abrirGaveta: false,
    );
    final orders = _formatter.formatOrders(ticketPrint, printerConfig, esLite: esLite);
    final bytes = await _escPosGenerator.buildFromOrders(
      orders,
      paperWidthMm: blePrinter.paperWidthMm,
    );

    await printerService.ensureConnected(blePrinter);
    await printerService.printBytes(bytes);
    return PrintCoffeResult(printed: true);
  }

  /// Impresión automática post-venta por Bluetooth BLE, paridad de [autoprint]
  /// para empresas con tipoImpresionMovil = BLUETOOTH_BLE. Imprime también la
  /// versión lite si la empresa la tiene activada.
  /// Lanza [PrinterException] si el transporte BLE falla.
  Future<void> autoprintBle({
    required int ticketId,
    required PrinterService printerService,
    required PrinterDevice blePrinter,
    required ConfigCompany config,
  }) async {
    if (config.impresionAutomatica != true) return;

    await printComprobanteBle(
      ticketId: ticketId,
      printerService: printerService,
      blePrinter: blePrinter,
    );

    if (config.imprimirBoletaLite == true) {
      await printComprobanteBle(
        ticketId: ticketId,
        printerService: printerService,
        blePrinter: blePrinter,
        esLite: true,
      );
    }
  }

  /// Impresión automática post-venta. Evalúa [ConfigCompany] para decidir si
  /// imprimir, y si corresponde, imprime también la versión lite.
  ///
  /// Llamar tras crear un comprobante (venta directa o pedido restaurante).
  Future<void> autoprint({
    required int ticketId,
    required String pdfUrl,
    required Printer printer,
    required bool escPos,
    required String officeCode,
    required int? idCompany,
    required ConfigCompany config,
  }) async {
    if (config.impresionAutomatica != true) return;
    if (config.clienteImpresion != 'COFFE') return;

    await printComprobante(
      ticketId: ticketId,
      pdfUrl: pdfUrl,
      printer: printer,
      escPos: escPos,
      officeCode: officeCode,
      idCompany: idCompany,
      esLite: false,
    );

    if (config.imprimirBoletaLite == true && escPos) {
      await printComprobante(
        ticketId: ticketId,
        pdfUrl: pdfUrl,
        printer: printer,
        escPos: escPos,
        officeCode: officeCode,
        idCompany: idCompany,
        esLite: true,
      );
    }
  }

  // ---------------------------------------------------------------------------

  Future<TicketPrint?> _fetchTicketPrint(int ticketId) async {
    try {
      final response = await _dio.get('/ticket-esc-pos/invoice/$ticketId');
      return TicketPrint.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[ComprobantePrint] No se pudo obtener el ticket $ticketId para imprimir: $e');
      return null;
    }
  }
}
