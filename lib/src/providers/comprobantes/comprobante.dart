import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/repositories/ticket_sale_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/tickets_sale_repository.dart';
import 'package:teki_app/src/utils/notifications.dart';

final comprobanteProvider = StateNotifierProvider<ComprobanteNotifier, ComprobanteState>((ref) {
  final repo = TicketSaleRepositoryImpl();
  return ComprobanteNotifier(repository: repo, ref: ref);
});

class ComprobanteNotifier extends StateNotifier<ComprobanteState> {
  final TicketsSaleRepository repository;
  final Ref ref;
  ComprobanteNotifier({required this.repository, required this.ref})
      : super(ComprobanteState.initial());

    Future<Ticket> fetchComprobanteById(int id) async {
    // Avoid refetching if we already have the same ticket loaded
    if (state.id == id && (state.ticket.id ?? 0) > 0 && !state.isLoading) {
      return state.ticket;
    }

    state = state.copyWith(isLoading: true, id: id);

    try {
      final ticket = await repository.getTicketById(id);
      state = state.copyWith(ticket: ticket, isLoading: false);
      return ticket;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      errorNotification("Error al cargar el comprobante: $e");
      return Future.error(e.toString());
    }
  }

  // metodo para 

  void clearState() {
    state = ComprobanteState.initial();
  }
}

class ComprobanteState {
  final int id;
  final Ticket ticket;
  final bool isLoading;
  final String? error;

  ComprobanteState({
    required this.id,
    required this.ticket,
    required this.isLoading,
    this.error,
  });

  factory ComprobanteState.initial() {
    return ComprobanteState(
      id: 0,
      ticket: Ticket(),
      isLoading: false,
      error: null,
    );
  }

  ComprobanteState copyWith({
    int? id,
    Ticket? ticket,
    bool? isLoading,
    String? error,
  }) {
    return ComprobanteState(
      id: id ?? this.id,
      ticket: ticket ?? this.ticket,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
