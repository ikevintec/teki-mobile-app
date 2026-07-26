// tickets_sale_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/totales_comprobantes.dart';
import 'package:teki_app/src/data/models/teki_model/totales_forma_pagos.dart';
import 'package:teki_app/src/data/repositories/ticket_sale_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/tickets_sale_repository.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/notifications.dart';
import 'package:teki_app/src/utils/query_params_builders.dart';

final comprobantesSaleProvider =
    StateNotifierProvider<ComprobantesNotifier, ComprobantesState>((ref) {
  final repo = TicketSaleRepositoryImpl();
  return ComprobantesNotifier(repository: repo, ref: ref);
});

/// Rol que permite ver las ventas de todos los vendedores. Sin este rol, el
/// usuario solo puede ver sus propias ventas (vendedor fijo de la sesión).
const String kRoleVerTodosVendedores = 'VENTAS_VER_VENTAS_TODOS_VENDEDORES';

/// Indica si el usuario en sesión puede filtrar por cualquier vendedor.
final puedeVerTodosVendedoresProvider = Provider<bool>((ref) {
  final roles = ref.watch(sesionProvider).roles ?? const <String>[];
  return roles.contains(kRoleVerTodosVendedores);
});

/// Rol que permite editar comprobantes emitidos.
const String kRoleEditar = 'VENTAS_EDITAR';

/// Indica si el usuario en sesión tiene permiso para editar comprobantes.
final puedeEditarProvider = Provider<bool>((ref) {
  final roles = ref.watch(sesionProvider).roles ?? const <String>[];
  return roles.contains(kRoleEditar);
});

/// Rol que permite anular comprobantes.
const String kRoleAnular = 'VENTAS_ANULAR';

/// Indica si el usuario en sesión tiene permiso para anular comprobantes.
final puedeAnularProvider = Provider<bool>((ref) {
  final roles = ref.watch(sesionProvider).roles ?? const <String>[];
  return roles.contains(kRoleAnular);
});

/// Determina si un comprobante puede anularse según su tipo y estado.
bool canAnular(Ticket comprobante) {
  // SI ESTA ANULADO YA NO MUESTRA LA OPCION
  if(comprobante.anulado == true){
    return false;
  }

  // BOLETA Y FACTURA
  if (comprobante.estadoSunat == 'ANULA') {
    return false;
  }

  // FACTURA
  if (comprobante.tipoComprobante == '01' &&
      comprobante.estadoSunat != 'ACEPT') {
    return false;
  }
  if (comprobante.tipoComprobante == '07' &&
      comprobante.estadoSunat != 'ACEPT' &&
      comprobante.tipoComprobanteAfectado == '01') {
    return false;
  }
  if (comprobante.tipoComprobante == '08' &&
      comprobante.estadoSunat != 'ACEPT' &&
      comprobante.tipoComprobanteAfectado == '01') {
    return false;
  }

  // BOLETA
  if (comprobante.tipoComprobante == '03' &&
      (comprobante.estado == '01' || comprobante.estado == '02')) {
    return true;
  }
  if (comprobante.tipoComprobante == '07' &&
      comprobante.tipoComprobanteAfectado == '03' &&
      (comprobante.estado == '01' || comprobante.estado == '02')) {
    return true;
  }
  if (comprobante.tipoComprobante == '08' &&
      comprobante.tipoComprobanteAfectado == '03' &&
      (comprobante.estado == '01' || comprobante.estado == '02')) {
    return true;
  }
  if (comprobante.tipoComprobante == '03' &&
      (comprobante.estado == '07' || comprobante.estado == '09')) {
    return false;
  }
  if (comprobante.tipoComprobante == 'NV' && comprobante.estado == '08') {
    return false;
  }

  return true;
}

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

  Future<void> loadFirstPage({
    required String desde, 
    required String hasta,
    String? serie,
    String? numero,
    List<String>? tiposComprobante,
    List<String>? metodosPago,
    String? estado,
    int? idVendedor,
  }) async {
    // Si no tiene permiso para ver todos los vendedores, se fuerza siempre el
    // vendedor de la sesión (comportamiento anterior). Con permiso: se respeta
    // el filtro seleccionado (null conserva el actual, 0 = todos).
    final int? resolvedVendedor = ref.read(puedeVerTodosVendedoresProvider)
        ? idVendedor
        : (ref.read(sesionProvider).login.user?.id ?? 0);

    state = state.copyWith(
      filtroDesde: desde,
      filtroHasta: hasta,
      filtroRucEmisor: ref.read(sesionProvider).companySelected?.ruc ?? '',
      idPuntoVenta: ref.read(sesionProvider).office?.id ?? 0,
      idVendedor: resolvedVendedor,
      tickets: [],
      hasMore: true,
      isLoading: true,
      pageNumber: 0,
      // Nuevos filtros adicionales
      filtroSerie: serie, // Permitir strings vacíos igual que en updateFilters
      filtroNumero: numero, // Permitir strings vacíos igual que en updateFilters
      filtroTipoComprobante: tiposComprobante?.isNotEmpty == true ? tiposComprobante : null,
      idMetodoPago: metodosPago?.isNotEmpty == true ? metodosPago : null,
      filtroEstado: estado,
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

  // Método para actualizar filtros sin hacer búsqueda inmediata
  void updateFilters({
    String? serie,
    String? numero,
    List<String>? tiposComprobante,
    List<String>? metodosPago,
    String? estado,
    int? idVendedor,
  }) {
    state = state.copyWith(
      filtroSerie: serie, // Permitir strings vacíos
      filtroNumero: numero, // Permitir strings vacíos
      filtroTipoComprobante: tiposComprobante?.isNotEmpty == true ? tiposComprobante : null,
      idMetodoPago: metodosPago?.isNotEmpty == true ? metodosPago : null,
      filtroEstado: estado,
      // 0 = todos los vendedores; null conserva la selección actual
      idVendedor: idVendedor,
    );
  }

  // Método para limpiar filtros adicionales (mantiene fechas)
  Future<void> clearAdditionalFilters() async {
    // Hacer búsqueda manteniendo solo las fechas actuales
    state = ComprobantesState(
      tickets: [],
      isLoading: true,
      hasMore: true,
      pageNumber: 0,
      page: 0,
      perPage: state.perPage,
      limit: state.limit,
      filtroDesde: state.filtroDesde,
      filtroHasta: state.filtroHasta,
      ruc: state.ruc,
      idPuntoVenta: state.idPuntoVenta,
      idVendedor: 0, // 0 = todos los vendedores
      filtroRucEmisor: state.filtroRucEmisor,
      totalesPorMoneda: [],
    );
    await loadFirstPage(
      desde: state.filtroDesde,
      hasta: state.filtroHasta,
    );
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

  /// Desglose por método de pago del filtro actual. Se consulta bajo demanda
  /// (al abrir el sheet de desglose), no en cada recarga de la lista.
  Future<List<TotalVentasFormaPago>> fetchTotalesFormaPago() {
    return repository.getTotalesFormaPago(buildComprobanteQueryParams(state));
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
  // Nuevos filtros adicionales
  final String? filtroSerie;
  final String? filtroNumero;
  final List<String>? filtroTipoComprobante;
  final List<String>? idMetodoPago;
  final String? filtroEstado;

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
    required this.totalesPorMoneda,
    // Nuevos filtros adicionales
    this.filtroSerie,
    this.filtroNumero,
    this.filtroTipoComprobante,
    this.idMetodoPago,
    this.filtroEstado,
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
        totalesPorMoneda: [],
        // Nuevos filtros adicionales inicializados como null
        filtroSerie: null,
        filtroNumero: null,
        filtroTipoComprobante: null,
        idMetodoPago: null,
        filtroEstado: null,
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
    int? perPage,
    String? filtroRucEmisor,
    List<TotalesPorMoneda>? totalesPorMoneda,
    // Nuevos filtros adicionales
    String? filtroSerie,
    String? filtroNumero,
    List<String>? filtroTipoComprobante,
    List<String>? idMetodoPago,
    String? filtroEstado,
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
      perPage: perPage ?? this.perPage,
      filtroRucEmisor: filtroRucEmisor ?? this.filtroRucEmisor,
      totalesPorMoneda: totalesPorMoneda ?? this.totalesPorMoneda,
      // Nuevos filtros adicionales
      filtroSerie: filtroSerie ?? this.filtroSerie,
      filtroNumero: filtroNumero ?? this.filtroNumero,
      filtroTipoComprobante: filtroTipoComprobante ?? this.filtroTipoComprobante,
      idMetodoPago: idMetodoPago ?? this.idMetodoPago,
      filtroEstado: filtroEstado ?? this.filtroEstado,
    );
  }
}
