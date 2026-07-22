import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/esc_pos/command_print.dart';
import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/order_restaurant_change_status_items.dart';
import 'package:teki_app/src/data/models/teki_model/printer.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/production_area.dart';
import 'package:teki_app/src/shared/services/command_esc_pos_formatter.dart';
import 'package:teki_app/src/shared/services/print_coffe_service.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/notifications.dart';

class CommandPrintService {
  final Dio _dio = ApiClient.dio;
  final PrintCoffeService _printCoffeService = PrintCoffeService();
  final CommandEscPosFormatter _escPosFormatter = CommandEscPosFormatter();

  /// Imprime las comandas de anulación de todos los items afectados por un
  /// cambio de estado de orden (p. ej. anular la orden completa).
  Future<void> printCancellation({
    required List<OrderRestaurantChangeStatusItems> changeItems,
    required Office puntoVenta,
    required bool escPos,
    required String? clientPrinter,
    required int? idCompany,
  }) async {
    for (final ci in changeItems) {
      final commandId = ci.comanda?.id;
      if (commandId == null) continue;
      final itemIds =
          (ci.items ?? []).map((item) => item.id).whereType<int>().toList();
      await processCommand(
        commandId: commandId,
        puntoVenta: puntoVenta,
        escPos: escPos,
        clientPrinter: clientPrinter,
        idCompany: idCompany,
        anulacion: true,
        itemAfectado: itemIds,
      );
    }
  }

  /// Procesa una comanda guardada: detecta áreas de producción y dispara impresión.
  Future<void> processCommand({
    required int commandId,
    required Office puntoVenta,
    required bool escPos,
    required String? clientPrinter,
    required int? idCompany,
    bool anulacion = false,
    List<int> itemAfectado = const <int>[],
  }) async {
    if (clientPrinter != 'COFFE') return;

    Command command;
    try {
      final response = await _dio.get('/commands/$commandId');
      command = Command.fromJson(response.data);
    } catch (e) {
      debugPrint('[CommandPrint] No se pudo obtener la comanda $commandId, se omite impresión: $e');
      errorNotification('No se pudo imprimir la comanda');
      return;
    }

    final areasProductions = <ProductionArea>[];

    void processProduct(Product producto) {
      final area = producto.categoria?.areaProduccion;
      if (area == null) return;
      final hasMatchingPrinter = area.impresoras?.any((imp) =>
              imp.puntoVenta?.id == puntoVenta.id &&
              (imp.tipoImpresora == null || imp.tipoImpresora == 'TICKETERA')) ??
          false;
      if (hasMatchingPrinter) areasProductions.add(area);
    }

    for (final cd in command.items ?? []) {
      final producto = cd.producto as Product?;
      if (producto == null) continue;
      if (producto.tipoProducto == 'COMBO') {
        processProduct(producto);
        for (final gp in producto.comboPlatillos ?? []) {
          processProduct(gp);
        }
      } else {
        processProduct(producto);
      }

      for (final gp in cd.grupoProductoOpciones ?? []) {
        if (gp.producto?.categoria?.areaProduccion.impresoras?.any((imp) => imp.puntoVenta?.id == puntoVenta.id) == true) {
          processProduct(gp.producto);
        }
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

      final params = 'idArea=$idArea&anulacion=$anulacion${itemAfectado.map((id) => '&itemAfectado=$id').join()}';
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
      final idx = part.indexOf('=');
      if (idx < 0) continue;
      final key = part.substring(0, idx);
      final value = part.substring(idx + 1);
      if (map.containsKey(key)) {
        final existing = map[key];
        if (existing is List) {
          existing.add(value);
        } else {
          map[key] = [existing, value];
        }
      } else {
        map[key] = value;
      }
    }
    return map;
  }
}
