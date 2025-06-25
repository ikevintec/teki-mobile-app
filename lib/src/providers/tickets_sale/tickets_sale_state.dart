import 'package:teki_app/src/data/models/teki_model/ticket.dart';

class TicketSaleState {
  final List<Ticket> tickets;
  final Ticket? selectedTicket;
  final bool isLoading;
  final String? error;
  final int pageNumber;
  final int perPage;
  final String filterGlobal;
  final int? totalElements;
  final bool paginacion;
  final String? errorMessage;

  TicketSaleState({
    required this.tickets,
    required this.selectedTicket,
    required this.isLoading,
    required this.error,
    required this.pageNumber,
    required this.perPage,
    required this.filterGlobal,
    required this.totalElements,
    required this.paginacion,
    required this.errorMessage,
  });

  TicketSaleState copyWith({
    List<Ticket>? tickets,
    Ticket? selectedTicket,
    bool? isLoading,
    String? error,
    int? pageNumber,
    int? perPage,
    String? filterGlobal,
    int? totalElements,
    bool? paginacion,
    String? errorMessage,
  }) {
    return TicketSaleState(
      tickets: tickets ?? this.tickets,
      selectedTicket: selectedTicket ?? this.selectedTicket,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      pageNumber: pageNumber ?? this.pageNumber,
      perPage: perPage ?? this.perPage,
      filterGlobal: filterGlobal ?? this.filterGlobal,
      totalElements: totalElements ?? this.totalElements,
      paginacion: paginacion ?? this.paginacion,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  factory TicketSaleState.initial() => TicketSaleState(
        tickets: [],
        selectedTicket: null,
        isLoading: false,
        error: null,
        pageNumber: 0,
        perPage: 20,
        filterGlobal: '',
        totalElements: null,
        paginacion: false,
        errorMessage: null,
      );
}
