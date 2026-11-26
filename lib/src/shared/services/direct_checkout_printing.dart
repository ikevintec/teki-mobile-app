import 'package:teki_app/src/data/models/teki_model/config.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/sale_station.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/providers/restaurant/direct_checkout/direct_checkout_service.dart';
import 'package:teki_app/src/shared/services/command_print_service.dart';
import 'package:teki_app/src/shared/services/comprobante_print_service.dart';
import 'package:teki_app/src/utils/constants.dart';

/// Printing is deliberately downstream of the confirmed, idempotent save.
/// A printer failure cannot trigger another order, payment, or receipt.
class DirectCheckoutPrinting {
  final CommandPrintService commands;
  final ComprobantePrintService receipts;
  DirectCheckoutPrinting({
    CommandPrintService? commands,
    ComprobantePrintService? receipts,
  }) : commands = commands ?? CommandPrintService(),
       receipts = receipts ?? ComprobantePrintService();

  Future<List<String>> process(
    DirectCheckoutResult result, {
    required ConfigCompany config,
    required Office office,
    required SaleStation station,
    int? company,
    Future<void> Function(Ticket)? printBle,
    Future<bool> Function()? claimPrinting,
  }) async {
    final warnings = <String>[];
    if (claimPrinting != null) {
      try {
        if (!await claimPrinting()) {
          return [
            'La impresión ya se intentó. Revise cocina y reimprima si hace falta.',
          ];
        }
      } catch (_) {
        return [
          'Pedido guardado. No se pudo iniciar la impresión; reimprima desde el pedido.',
        ];
      }
    }
    if (!result.automaticPrinting) {
      return [
        'Pedido recuperado. Puede reimprimir manualmente sin volver a cobrar.',
      ];
    }
    if ((config.imprimirPedidoComandaSinComprobante == true ||
            result.action == 'INVOICE') &&
        config.clienteImpresion == 'COFFE') {
      final ids = (result.order.comandas ?? [])
          .map((c) => c.id)
          .whereType<int>()
          .toSet();
      if (ids.isEmpty) {
        warnings.add('Pedido guardado sin comanda disponible para imprimir.');
      }
      for (final id in ids) {
        try {
          await commands.processCommand(
            commandId: id,
            puntoVenta: office,
            escPos: config.imprimeTicketsEscPos ?? false,
            clientPrinter: config.clienteImpresion,
            idCompany: company,
          );
        } catch (_) {
          warnings.add('Pedido guardado. No se pudo imprimir la comanda.');
        }
      }
    }
    final ticket = result.check.comprobante;
    if (result.action == 'INVOICE' &&
        ticket?.id != null &&
        config.impresionAutomatica == true) {
      try {
        if (config.tipoImpresionMovil == 'BLUETOOTH_BLE') {
          if (printBle != null) await printBle(ticket!);
        } else if (config.clienteImpresion == 'COFFE' &&
            station.impresoraComprobante != null) {
          final url =
              '${Environment.apiUrl}/public/pdf/tickets/${ticket!.uuid}/${ticket.identificadorDocumento}?tipo=${config.tipoImpresion ?? 'A4'}';
          await receipts.autoprint(
            ticketId: ticket.id!,
            pdfUrl: url,
            printer: station.impresoraComprobante!,
            escPos: config.imprimeTicketsEscPos ?? false,
            officeCode: office.codigo ?? '',
            idCompany: company,
            config: config,
          );
        }
      } catch (_) {
        warnings.add(
          'Comprobante generado. No se pudo imprimir; puede reintentar desde el visor.',
        );
      }
    }
    return warnings;
  }
}
