import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/teki_model/printer.dart';
import 'package:teki_app/src/shared/services/print_coffe_service.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';

class ComprobantePrintService {
  final Dio _dio = ApiClient.dio;
  final PrintCoffeService _printCoffeService = PrintCoffeService();

  /// Imprime un comprobante vía Coffe (ESC/POS o PDF).
  /// Lanza [PrintCoffeException] si el servicio de impresión falla.
  Future<void> printComprobante({
    required int ticketId,
    required String pdfUrl,
    required Printer printer,
    required bool escPos,
    required String officeCode,
    required int? idCompany,
  }) async {
    final printerOfficeCode =
        '$officeCode${printer.codigoCoffe != null ? '_${printer.codigoCoffe}' : ''}';

    if (escPos) {
      dynamic escPosData;
      try {
        final response = await _dio.get('/ticket-esc-pos/invoice/$ticketId');
        escPosData = response.data;
      } catch (_) {
        // Si no se puede obtener los datos ESC/POS, no imprimir
        return;
      }
      await _printCoffeService.printCoffe({
        'printerName': printer.nombre,
        'orders': escPosData,
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
}
