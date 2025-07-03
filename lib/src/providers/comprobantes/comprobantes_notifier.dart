// tickets_sale_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/repositories/ticket_sale_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/tickets_sale_repository.dart';
import 'package:teki_app/src/utils/notifications.dart';

final ticketsSaleProvider =
    StateNotifierProvider.autoDispose<TicketsNotifier, TicketsState>((ref) {
  final repo = TicketSaleRepositoryImpl();
  return TicketsNotifier(repository: repo);
});

class TicketsNotifier extends StateNotifier<TicketsState> {
  final TicketsSaleRepository repository;

  TicketsNotifier({required this.repository}) : super(TicketsState.initial());

  Future<void> fetchInitialTickets({
    required String filtroDesde,
    required String filtroHasta,
    required String ruc,
    required int idPuntoVenta,
    required int idVendedor,
  }) async {
    state = state.copyWith(
      isLoading: true,
      page: 0,
      tickets: [],
      hasMore: true,
      filtroDesde: filtroDesde,
      filtroHasta: filtroHasta,
      ruc: ruc,
      idPuntoVenta: idPuntoVenta,
      idVendedor: idVendedor,
    );

    await fetchMoreTickets();
  }

  Future<void> fetchMoreTickets() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final newTickets = await repository.getComprobantes(
        filtroDesde: state.filtroDesde,
        filtroHasta: state.filtroHasta,
        rucEmisor: state.ruc,
        idPuntoVenta: state.idPuntoVenta,
        idVendedor: state.idVendedor,
        page: state.page,
        size: state.limit,
      );

      state = state.copyWith(
        isLoading: false,
        page: state.page + 1,
        tickets: [...state.tickets, ...newTickets],
        hasMore: newTickets.length == state.limit,
      );
    } catch (e) {
      errorNotification("Error al cargar comprobantes: $e");
      state = state.copyWith(isLoading: false);
    }
  }
}

class TicketsState {
  final List<Ticket> tickets;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final int limit;
  final String filtroDesde;
  final String filtroHasta;
  final String ruc;
  final int idPuntoVenta;
  final int idVendedor;

  TicketsState({
    required this.tickets,
    required this.isLoading,
    required this.hasMore,
    required this.page,
    required this.limit,
    required this.filtroDesde,
    required this.filtroHasta,
    required this.ruc,
    required this.idPuntoVenta,
    required this.idVendedor,
  });

  factory TicketsState.initial() => TicketsState(
        tickets: [],
        isLoading: false,
        hasMore: true,
        page: 0,
        limit: 5,
        filtroDesde: '',
        filtroHasta: '',
        ruc: '',
        idPuntoVenta: 0,
        idVendedor: 0,
      );

  TicketsState copyWith({
    List<Ticket>? tickets,
    bool? isLoading,
    bool? hasMore,
    int? page,
    int? limit,
    String? filtroDesde,
    String? filtroHasta,
    String? ruc,
    int? idPuntoVenta,
    int? idVendedor,
  }) {
    return TicketsState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      filtroDesde: filtroDesde ?? this.filtroDesde,
      filtroHasta: filtroHasta ?? this.filtroHasta,
      ruc: ruc ?? this.ruc,
      idPuntoVenta: idPuntoVenta ?? this.idPuntoVenta,
      idVendedor: idVendedor ?? this.idVendedor,
    );
  }
}
