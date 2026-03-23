import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/esc_pos/ticket_print.dart';
import 'package:teki_app/src/data/models/teki_model/config.dart';
import 'package:teki_app/src/data/models/teki_model/printer.dart';
import 'package:teki_app/src/shared/services/invoice_esc_pos_formatter.dart';
import 'package:teki_app/src/shared/services/print_coffe_service.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';

class ComprobantePrintService {
  final Dio _dio = ApiClient.dio;
  final PrintCoffeService _printCoffeService = PrintCoffeService();
  final InvoiceEscPosFormatter _formatter = InvoiceEscPosFormatter();

  /// Imprime un comprobante vía Coffe (ESC/POS o PDF).
  /// [esLite] = true genera la versión reducida (boleta lite).
  /// Lanza [PrintCoffeException] si el servicio de impresión falla.
  Future<void> printComprobante({
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
      if (ticketPrint == null) return;

      final orders = _formatter.format(ticketPrint, printer, esLite: esLite);
      await _printCoffeService.printCoffe({
        'printerName': printer.nombre,
        'orders': orders,
        'event': 'printEscPos',
        'idCompany': idCompany,
        'officeCode': printerOfficeCode,
      });
    } else {
      await _printCoffeService.printCoffe({
        'url': pdfUrl,
        'scale': printer.coffeEscala ?? 2.5,
        'printerName': printer.nombre,
        'event': 'printPdf',
        'idCompany': idCompany,
        'officeCode': printerOfficeCode,
      });
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
    } catch (_) {
      return null;
    }
  }
}
