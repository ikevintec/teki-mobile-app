import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/domain/repositories/tickets_sale_repository.dart';
import 'package:teki_app/src/providers/tickets_sale/tickets_sale_state.dart';
import 'package:teki_app/src/utils/notifications.dart';

class TicketSaleNotifier extends StateNotifier<TicketSaleState> {
  final TicketsSaleRepository ticketsSaleRepository;

  TicketSaleNotifier({required this.ticketsSaleRepository})
      : super(TicketSaleState.initial());

  Future<List<Ticket>> getTicketsPorTipoYSerie(
      String tipo, String serie) async {
    state = state.copyWith(isLoading: true);
    try {
      final tickets = await ticketsSaleRepository.getTicketNumeros(tipo, serie);
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

  Future<void> getNextTicketNumberPorDefecto() async {
    const tipo = "01"; // Boleta
    const serie = "B001";

    state = state.copyWith(isLoading: true);
    try {
      // ✅ Esto ya es un Ticket completo
      final ticket =
          await ticketsSaleRepository.getNextTicketNumber(tipo, serie);

      state = state.copyWith(
        selectedTicket: ticket,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      errorNotification("Error al obtener número: $e");
    }
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
}
