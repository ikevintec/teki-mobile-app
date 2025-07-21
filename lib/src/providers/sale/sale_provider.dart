import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/cashRegisterDetail.dart';
import 'package:teki_app/src/data/models/teki_model/paymentDetail.dart';
import 'package:teki_app/src/data/models/teki_model/paymentMethod.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/ticketFee.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/data/repositories/ticket_sale_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/tickets_sale_repository.dart';
import 'package:teki_app/src/providers/auth/login.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_provider.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/utils/notifications.dart';

final ticketProvider = StateNotifierProvider<TicketNotifier, TicketProvider>((ref) {
  final TicketsSaleRepository ticketsSaleRepository = TicketSaleRepositoryImpl();
  return TicketNotifier(ref: ref, ticketsSaleRepository: ticketsSaleRepository);
}
);

class TicketNotifier extends StateNotifier<TicketProvider> {
  final TicketsSaleRepository ticketsSaleRepository;
  final Ref ref;
  TicketNotifier({required this.ref, required this.ticketsSaleRepository,})
      : super(TicketProvider(
            ticket: Ticket(
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
                codigoTipoOperacion: '0101', // Por defecto
                vendedor: ref.read(authStateProvider).user,
                puntoVenta: ref.read(sesionProvider).office,
                fechaEmisionDate: DateTime.now())));

  void updateTicket(Ticket ticket) {
    state = state.copyWith(ticket: ticket);
  }

  void setTipoComprobante(String tipoDocumento) {
    Ticket ticketToUpdate =
        state.ticket.copyWith(tipoComprobante: tipoDocumento);
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
    Ticket ticketToUpdate = state.ticket.copyWith(
        fechaEmision: DateFormat('yyyy-MM-dd').format(fechaEmision),
        horaEmision: DateFormat('HH:mm:ss').format(fechaEmision),
        fechaEmisionDate: fechaEmision);
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
      tipoDocumentoReceptor: clienteSaleProviderData.customer.tipoDocumento,
      numeroDocumentoReceptor: clienteSaleProviderData.customer.numeroDocumento,
      denominacionReceptor: clienteSaleProviderData.customer.razonSocial,
      direccionReceptor: clienteSaleProviderData.customer.direccion,
      emailReceptor: clienteSaleProviderData.customer.email,
      telefonoReceptor: clienteSaleProviderData.customer.telefono,
      puntoVenta: ref.read(sesionProvider).office,
      estacionVenta: ref.read(sesionProvider).saleStation,
    );
    state = state.copyWith(ticket: ticketToUpdate);
  }

  void setAgruparItems(bool agrupar) {
    Ticket ticketToUpdate = state.ticket.copyWith(agruparItems: agrupar);
    state = state.copyWith(ticket: ticketToUpdate);
  }

  void setMovimientoCaja({required double total, required  String pagado, required String cambio, required  String numOperacion, required PaymentMethod metodoPago}) {
    Ticket ticketToUpdate = state.ticket.copyWith(
      cuotas: null,
      movimientoCaja: CashRegisterDetail(
        pagos: [
          PaymentDetail(
            formaPago: metodoPago.formaPago,
              monto: total,
              montoPagado: double.parse(pagado),
              metodoPago: metodoPago,
              numeroOperacion: numOperacion,
              nombre: metodoPago.nombre,
              tipoTarjeta: metodoPago.tipoTarjeta,
              )
        ],
      ),
      cambio: double.parse(cambio),
    );
    state = state.copyWith(ticket: ticketToUpdate);
  }

  void setCuotas(List<TicketFee> cuotas) {
    Ticket ticketToUpdate = state.ticket.copyWith(movimientoCaja: null,cuotas: cuotas);
    state = state.copyWith(ticket: ticketToUpdate);
  }

  void setVendedor(User vendedor) {
    Ticket ticketToUpdate = state.ticket.copyWith(vendedor: vendedor);
    state = state.copyWith(ticket: ticketToUpdate);
  }

  void resetTicket() {
    state = TicketProvider(ticket: Ticket());
  }

  Future<Ticket?> createTicket() async {
    try {
      return await ticketsSaleRepository.createTicket(state.ticket);
    } catch (e) {
      errorNotification("Error al crear el ticket: $e");
      return null;
    }
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
