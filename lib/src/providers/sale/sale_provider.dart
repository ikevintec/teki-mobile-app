import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/providers/auth/login.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_provider.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';

final ticketProvider = StateNotifierProvider<TicketNotifier, TicketProvider>(
  (ref) => TicketNotifier(ref: ref),
);

class TicketNotifier extends StateNotifier<TicketProvider> {
  final Ref ref;
  TicketNotifier({required this.ref})
      : super(TicketProvider(ticket: Ticket(
          items: [],
          incIgv: true,
          tipoComprobante: 'NV', // Factura
          codigoMoneda: 'PEN',
          agruparItems: false,
          cambio: 0,
          despachoPosterior: false,
          isRetencion: false,
          pagoAnticipado: false,
          tipoVenta: "CONTADO",
          ordenCompra: '0101',
          vendedor: ref.read(authStateProvider).user,
          puntoVenta: ref.read(sesionProvider).office,
          fechaEmisionDate: DateTime.now()
        )));

  void updateTicket(Ticket ticket) {
    state = state.copyWith(ticket: ticket);
  }

  void setTipoComprobante(String tipoDocumento) {
    Ticket ticketToUpdate = state.ticket.copyWith(tipoComprobante: tipoDocumento);
    state = state.copyWith(ticket: ticketToUpdate);
  }

  void setTipoOperacion(String codigoTipoOperacion) {
    Ticket ticketToUpdate =
        state.ticket.copyWith(codigoTipoOperacion: codigoTipoOperacion);
    state = state.copyWith(ticket: ticketToUpdate);
  }

  void setNumeroOrden(String numeroOrden) {
    Ticket ticketToUpdate = state.ticket.copyWith(ordenCompra: numeroOrden);
    state = state.copyWith(ticket: ticketToUpdate);
  }

  void setFechaEmision(DateTime fechaEmision) {
    Ticket ticketToUpdate = state.ticket.copyWith(fechaEmision: DateFormat('yyyy-MM-dd').format(fechaEmision), fechaEmisionDate: fechaEmision);
    state = state.copyWith(ticket: ticketToUpdate);
  }

  void setFechaVencimiento(DateTime fechaVencimiento) {
    Ticket ticketToUpdate = state.ticket.copyWith(
      fechaVencimiento: DateFormat('yyyy-MM-dd').format(fechaVencimiento),
      fechaVencimientoDate: fechaVencimiento,
    );
    state = state.copyWith(ticket: ticketToUpdate);
  }

  void setSerie(String serie) {
    Ticket ticketToUpdate = state.ticket.copyWith(serie: serie);
    state = state.copyWith(ticket: ticketToUpdate);
  }

  void setNumero(int numero) {
    Ticket ticketToUpdate = state.ticket.copyWith(numero: numero);
    state = state.copyWith(ticket: ticketToUpdate);
  }

  void setTicketsData() {
    final productSaleProviderData = ref.read(productSaleProvider);
    final clienteSaleProviderData = ref.read(customerSaleProvider);
    Ticket ticketToUpdate = state.ticket.copyWith(
      items: productSaleProviderData.productsSales,
      incIgv: productSaleProviderData.incIgv,
      tipoComprobante: productSaleProviderData.tipoComprobante,
      codigoMoneda: productSaleProviderData.currency?.codigoMoneda,
      cliente: clienteSaleProviderData.customer,
    );
    state = state.copyWith(ticket: ticketToUpdate);
  }

  void setVendedor(User vendedor) {
    Ticket ticketToUpdate = state.ticket.copyWith(vendedor: vendedor);
    state = state.copyWith(ticket: ticketToUpdate);
  }

  void resetTicket() {
    state = TicketProvider(ticket: Ticket());
  }
}

class TicketProvider {
  final Ticket ticket;
  TicketProvider({required this.ticket});
  TicketProvider copyWith({
    Ticket? ticket,
  }) {
    return TicketProvider(
      ticket: ticket ?? this.ticket,
    );
  }
}
