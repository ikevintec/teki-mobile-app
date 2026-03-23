import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/esc_pos/command_print.dart';
import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/printer.dart';
import 'package:teki_app/src/data/models/teki_model/productionArea.dart';
import 'package:teki_app/src/shared/services/command_esc_pos_formatter.dart';
import 'package:teki_app/src/shared/services/print_coffe_service.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/notifications.dart';

class CommandPrintService {
  final Dio _dio = ApiClient.dio;
  final PrintCoffeService _printCoffeService = PrintCoffeService();
  final CommandEscPosFormatter _escPosFormatter = CommandEscPosFormatter();

  /// Procesa una comanda guardada: detecta áreas de producción y dispara impresión.
  Future<void> processCommand({
    required int commandId,
    required Office puntoVenta,
    required bool escPos,
    required String? clientPrinter,
    required int? idCompany,
  }) async {
    if (clientPrinter != 'COFFE') return;

    Command command;
    try {
      final response = await _dio.get('/commands/$commandId');
      command = Command.fromJson(response.data);
    } catch (_) {
      return;
    }

    final areasProductions = <ProductionArea>[];

    void processProduct(dynamic producto) {
      final area = producto?.categoria?.areaProduccion as ProductionArea?;
      if (area == null) return;
      final hasMatchingPrinter = area.impresoras?.any((imp) =>
              imp.puntoVenta?.id == puntoVenta.id &&
              (imp.tipoImpresora == null || imp.tipoImpresora == 'TICKETERA')) ??
          false;
      if (hasMatchingPrinter) areasProductions.add(area);
    }

    for (final cd in command.items ?? []) {
      processProduct(cd.producto);
      for (final gp in cd.grupoProductoOpciones ?? []) {
        processProduct(gp.producto);
      }
    }

    final uniqueAreaIds = areasProductions.map((a) => a.id).toSet();

    for (final idArea in uniqueAreaIds) {
      final area = areasProductions.firstWhere((a) => a.id == idArea);
      final printer = area.impresoras?.firstWhere(
        (p) =>
            p.puntoVenta?.id == puntoVenta.id &&
            (p.tipoImpresora == null || p.tipoImpresora == 'TICKETERA'),
        orElse: () => Printer(),
      );
      if (printer?.id == null) continue;

      final params = 'idArea=$idArea&anulacion=false';
      await _printCommand(
        commandId: commandId,
        params: params,
        printer: printer!,
        escPos: escPos,
        clientPrinter: clientPrinter,
        officeCode: puntoVenta.codigo ?? '',
        idCompany: idCompany,
      );
    }
  }

  Future<void> _printCommand({
    required int commandId,
    required String params,
    required Printer printer,
    required bool escPos,
    required String? clientPrinter,
    required String officeCode,
    required int? idCompany,
  }) async {
    final tipoImpresion = _getTipoImpresion(printer, escPos);
    final printerOfficeCode =
        '$officeCode${printer.codigoCoffe != null ? '_${printer.codigoCoffe}' : ''}';

    if (tipoImpresion == 'ESCPOS') {
      try {
        final response = await _dio.get(
          '/ticket-esc-pos/command/$commandId',
          queryParameters: _paramsToMap(params),
        );
        final commandPrint = CommandPrint.fromJson(
          response.data as Map<String, dynamic>,
        );
        final orders = _escPosFormatter.format(commandPrint, printer);
        await _printCoffeService.printCoffe({
          'printerName': printer.nombre,
          'orders': orders,
          'event': 'printEscPos',
          'idCompany': idCompany,
          'officeCode': printerOfficeCode,
        });
      } on PrintCoffeException catch (e) {
        errorNotification(e.message);
      } catch (e) {
        errorNotification('Error al imprimir comanda: ${e.toString()}');
      }
    } else if (tipoImpresion == 'PDF') {
      final url = '${Environment.apiUrl}/public/pdf/command/$commandId?$params';
      await _printCoffeService.printCoffe({
        'url': url,
        'scale': printer.coffeEscala ?? 2.5,
        'printerName': printer.nombre,
        'event': 'printPdf',
        'idCompany': idCompany,
        'officeCode': printerOfficeCode,
      });
    }
  }

  String _getTipoImpresion(Printer printer, bool escPos) {
    final tipo = printer.tipoImpresion;
    if (tipo == null || tipo == 'GLOBAL') {
      return escPos ? 'ESCPOS' : 'PDF';
    }
    return tipo;
  }

  Map<String, dynamic> _paramsToMap(String params) {
    final map = <String, dynamic>{};
    for (final part in params.split('&')) {
      final kv = part.split('=');
      if (kv.length == 2) map[kv[0]] = kv[1];
    }
    return map;
  }
}
