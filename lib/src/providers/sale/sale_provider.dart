


import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';

final ticketProvider = StateNotifierProvider<TicketNotifier, TicketProvider>(
  (ref) => TicketNotifier(ticket: Ticket()),
);

class TicketNotifier extends StateNotifier<TicketProvider> {
  TicketNotifier({required Ticket ticket}) : super(TicketProvider(ticket: ticket));

  void updateTicket(Ticket ticket) {
    state = state.copyWith(ticket: ticket);
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