// tickets_sale_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/totalesComprobantes.dart';
import 'package:teki_app/src/data/repositories/ticket_sale_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/tickets_sale_repository.dart';
import 'package:teki_app/src/providers/auth/login.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/notifications.dart';
import 'package:teki_app/src/utils/query_params_builders.dart';

final comprobantesSaleProvider =
    StateNotifierProvider<ComprobantesNotifier, ComprobantesState>((ref) {
  final repo = TicketSaleRepositoryImpl();
  return ComprobantesNotifier(repository: repo, ref: ref);
});

class ComprobantesNotifier extends StateNotifier<ComprobantesState> {
  final TicketsSaleRepository repository;
  final Ref ref;
  ComprobantesNotifier({required this.repository, required this.ref})
      : super(ComprobantesState.initial());

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

  Future<void> loadFirstPage({required String desde, required String hasta}) async {
    state = state.copyWith(
      filtroDesde: desde,
      filtroHasta: hasta,
      filtroRucEmisor: ref.read(sesionProvider).companySelected?.ruc ?? '',
      idPuntoVenta: ref.read(sesionProvider).office?.id ?? 0,
      idVendedor: ref.read(authStateProvider).user?.id ?? 0,
      tickets: [],
      hasMore: true,
      isLoading: true,
      pageNumber: 0,
    );

    try {
      final newTickets =
          await repository.getComprobantes(buildComprobanteQueryParams(state));
      await getTotales();

      state = state.copyWith(
        isLoading: false,
        page: state.page + 1,
        pageNumber: state.pageNumber + 1,
        tickets: newTickets,
        hasMore: newTickets.length == state.limit && newTickets.isNotEmpty,
      );
    } catch (e) {
      errorNotification("Error al cargar comprobantes: $e");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> fetchMoreTickets() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final newTickets =
          await repository.getComprobantes(buildComprobanteQueryParams(state));

      state = state.copyWith(
        isLoading: false,
        page: state.page + 1,
        pageNumber: state.pageNumber + 1,
        tickets: [...state.tickets, ...newTickets],
        hasMore: newTickets.length == state.limit && newTickets.isNotEmpty,
      );
    } catch (e) {
      errorNotification("Error al cargar comprobantes: $e");
      state = state.copyWith(hasMore: false);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> getTotales() async {
    try {
      final totales = await repository
          .getTotalesPorMoneda(buildComprobanteQueryParams(state));
      state = state.copyWith(totalesPorMoneda: totales);
    } catch (e) {
      errorNotification("Error al obtener totales por moneda: $e");
    }
  }
}

class ComprobantesState {
  final List<Ticket> tickets;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final int pageNumber;
  final int perPage;
  final int limit;
  final String filtroDesde;
  final String filtroHasta;
  final String ruc;
  final int idPuntoVenta;
  final int idVendedor;
  final String filtroRucEmisor;
  final List<TotalesPorMoneda> totalesPorMoneda;

  ComprobantesState({
    required this.tickets,
    required this.isLoading,
    required this.hasMore,
    required this.pageNumber,
    required this.page,
    required this.perPage,
    required this.limit,
    required this.filtroDesde,
    required this.filtroHasta,
    required this.ruc,
    required this.idPuntoVenta,
    required this.idVendedor,
    required this.filtroRucEmisor,
    required this.totalesPorMoneda, // nuevo
  });

  factory ComprobantesState.initial() => ComprobantesState(
        tickets: [],
        isLoading: false,
        hasMore: true,
        pageNumber: 0,
        page: 0,
        perPage: 5, // Default page size
        limit: 5,
        filtroDesde: '',
        filtroHasta: '',
        ruc: '',
        idPuntoVenta: 0,
        idVendedor: 0,
        filtroRucEmisor: '',
        totalesPorMoneda: [], // nuevo
      );

  ComprobantesState copyWith({
    List<Ticket>? tickets,
    bool? isLoading,
    bool? hasMore,
    int? pageNumber,
    int? page,
    int? limit,
    String? filtroDesde,
    String? filtroHasta,
    String? ruc,
    int? idPuntoVenta,
    int? idVendedor,
    int? perPage, // This is not used in the state but can be added if needed
    String? filtroRucEmisor,
    List<TotalesPorMoneda>? totalesPorMoneda, // nuevo
  }) {
    return ComprobantesState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      pageNumber: pageNumber ?? this.pageNumber,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      filtroDesde: filtroDesde ?? this.filtroDesde,
      filtroHasta: filtroHasta ?? this.filtroHasta,
      ruc: ruc ?? this.ruc,
      idPuntoVenta: idPuntoVenta ?? this.idPuntoVenta,
      idVendedor: idVendedor ?? this.idVendedor,
      perPage: perPage ?? this.perPage, // Optional, can be used for pagination
      filtroRucEmisor: filtroRucEmisor ?? this.filtroRucEmisor,
      totalesPorMoneda: totalesPorMoneda ?? this.totalesPorMoneda,
    );
  }
}
