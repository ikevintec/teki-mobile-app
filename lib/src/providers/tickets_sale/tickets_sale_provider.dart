import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/additional_field.dart';
import 'package:teki_app/src/data/models/teki_model/guia_relacionada.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';

// REPOSITORIO
import 'package:teki_app/src/data/repositories/quotation_repository_impl.dart';
import 'package:teki_app/src/data/repositories/ticket_sale_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/quotation_repository.dart';
import 'package:teki_app/src/domain/repositories/tickets_sale_repository.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';

// NOTIFIER + STATE
import 'package:teki_app/src/providers/tickets_sale/tickets_sale_state.dart';
import 'package:teki_app/src/utils/notifications.dart';

final ticketSaleProvider = StateNotifierProvider<TicketSaleNotifier, TicketSaleState>((ref) {
  final TicketsSaleRepository ticketRepository = TicketSaleRepositoryImpl();
  final QuotationRepository quotationRepository = QuotationRepositoryImpl();
  return TicketSaleNotifier(
    ticketsSaleRepository: ticketRepository,
    quotationRepository: quotationRepository,
    ref: ref,
  );
});

class TicketSaleNotifier extends StateNotifier<TicketSaleState> {
  final TicketsSaleRepository ticketsSaleRepository;
  final QuotationRepository quotationRepository;
  final Ref ref;

  TicketSaleNotifier({
    required this.ticketsSaleRepository,
    required this.quotationRepository,
    required this.ref,
  }) : super(TicketSaleState.initial());

  Future<List<Ticket>> getTickets(String tipoDocumento, String serie) async {
    state = state.copyWith(isLoading: true);
    try {
      final tickets =
          await ticketsSaleRepository.getTicketNumeros(tipoDocumento, serie);
      state = state.copyWith(
        isLoading: false,
        tickets: tickets,
        totalElements: tickets.length,
      );
      return tickets;
    } catch (e) {
      errorNotification(e.toString());
      state = state.copyWith(isLoading: false);
      return [];
    }
  }

  Future<void> getNextTicketNumber() async {
    state = state.copyWith(isLoading: true);
    final ticketState = ref.read(ticketProvider);
    final tipoComprobante = ticketState.ticket.tipoComprobante ?? 'NV'; // Por defecto NV
    final serieSelected = ticketState.ticket.serie ?? '';
    try {
      final numero = ticketState.isQuotation
          ? await quotationRepository.getNextQuotationNumber(tipoComprobante, serieSelected)
          : await ticketsSaleRepository.getNextTicketNumber(tipoComprobante, serieSelected);
      ref.read(ticketProvider.notifier).setNumero(numero);
      state = state.copyWith(
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      errorNotification("Error al obtener número: $e");
    }
  }

  Future<void> obtenerNumerosSeries() async {
    final officeId = ref.read(sesionProvider).office?.id;
    if (officeId == null) throw Exception("Oficina no encontrada");
    String tipoComprobante = ref.read(ticketProvider).ticket.tipoComprobante ?? 'NV'; // Por defecto NV
    state = state.copyWith(isLoading: true);

    try {
      final numeros = await ticketsSaleRepository.getSeriesPorOficina(
          officeId, tipoComprobante);
      state = state.copyWith(isLoading: false,numeros: numeros);
    } catch (e) {
      state = state.copyWith(isLoading: false,numeros: []);
      errorNotification("Error al obtener series: $e");
    }
  }

  Future<List<Ticket>> getTicketss(String tipoDocumento, String serie) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final tickets =
          await ticketsSaleRepository.getTicketNumeros(tipoDocumento, serie);
      state = state.copyWith(
        isLoading: false,
        tickets: tickets,
        totalElements: tickets.length,
      );
      return tickets;
    } catch (e) {
      // Guardamos el mensaje en el estado
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Error al obtener tickets: $e",
      );
      return [];
    }
  }

  TicketNotifier getTicketNotifier(){
    return ref.read(ticketProvider.notifier);
  }


  void selectTicket(Ticket ticket) {
    state = state.copyWith(selectedTicket: ticket);
  }

  void clearSelection() {
    state = state.copyWith(selectedTicket: null);
  }

  void clearTickets() {
    state = state.copyWith(tickets: []);
  }

void setOtrosCampos(List<AditionalField> otrosCampos, List<GuiaRelacionada> guias, String observacion, String nCotizacion, String otrosAtributos){
  Ticket ticketToUpdate = ref.read(ticketProvider).ticket;
  ticketToUpdate = ticketToUpdate.copyWith(
    otrosTributos: double.parse(otrosAtributos.isEmpty ? '0': otrosAtributos),
    camposAdicionales: otrosCampos,
    guiasRelacionadas: guias,
    observacion: observacion,
    numeroCotizacion: nCotizacion
  );
  getTicketNotifier().updateTicket(ticketToUpdate);
  ref.read(productSaleProvider.notifier).calculoTotal();
}

}
