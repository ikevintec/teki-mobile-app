import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/orderRestaurant.dart';
import 'package:teki_app/src/data/repositories/orders_restaurant_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/orders_restaurant_repository.dart';
import 'package:teki_app/src/utils/query_params_builders.dart';

// All possible tipos
const List<String> kAllTipos = [
  'LOCAL',
  'PEDIDO_LOCAL_INTERNO',
  'PEDIDO_LOCAL',
  'PEDIDO_FORANEO',
  'PEDIDO_ONLINE',
];

// All possible estados
const List<String> kAllEstados = [
  'PENDIENTE',
  'PREPARADO',
  'PRECUENTA',
  'FINALIZADO',
  'CANCELADO',
];

final ordersRestaurantProvider = StateNotifierProvider.autoDispose<
    OrdersRestaurantNotifier, OrdersRestaurantState>(
  (ref) {
    final OrdersRestaurantRepository repository =
        OrdersRestaurantRepositoryImpl();
    return OrdersRestaurantNotifier(repository: repository);
  },
);

class OrdersRestaurantNotifier
    extends StateNotifier<OrdersRestaurantState> {
  final OrdersRestaurantRepository repository;

  OrdersRestaurantNotifier({required this.repository})
      : super(OrdersRestaurantState.initial());

  Future<void> initialize(int idPuntoVenta) async {
    state = state.copyWith(idPuntoVenta: idPuntoVenta, isLoading: true);
    await _fetchAndSet(resetList: true);
  }

  Future<void> loadNextPage() async {
    if (state.last || state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      pageNumber: state.pageNumber + 1,
    );
    await _fetchAndSet(resetList: false);
  }

  Future<void> refresh() async {
    state = state.copyWith(
      isLoading: true,
      pageNumber: 0,
      orders: [],
    );
    await _fetchAndSet(resetList: true);
  }

  void updateSearch(String value) {
    state = state.copyWith(
      nombreCliente: value,
      pageNumber: 0,
      orders: [],
      isLoading: true,
    );
    _fetchAndSet(resetList: true);
  }

  void updateTipo(String? tipo) {
    final List<String> tipos =
        tipo == null || tipo == 'TODOS' ? kAllTipos : [tipo];
    state = state.copyWith(
      selectedTipo: tipo ?? 'TODOS',
      tipos: tipos,
      pageNumber: 0,
      orders: [],
      isLoading: true,
    );
    _fetchAndSet(resetList: true);
  }

  void updateEstadoPago(String? value) {
    bool? pedidoFacturado;
    if (value == 'PAGADOS') pedidoFacturado = true;
    if (value == 'NO_PAGADOS') pedidoFacturado = false;
    state = state.copyWith(
      selectedEstadoPago: value ?? 'PAGADOS',
      pedidoFacturado: pedidoFacturado,
      clearPedidoFacturado: value == 'TODOS',
      pageNumber: 0,
      orders: [],
      isLoading: true,
    );
    _fetchAndSet(resetList: true);
  }

  void updateEstados(List<String> estados) {
    state = state.copyWith(
      estados: estados.isEmpty ? kAllEstados : estados,
      pageNumber: 0,
      orders: [],
      isLoading: true,
    );
    _fetchAndSet(resetList: true);
  }

  void updateFechas({String? desde, String? hasta, bool clearDesde = false, bool clearHasta = false}) {
    state = state.copyWith(
      desde: clearDesde ? null : (desde ?? state.desde),
      clearDesde: clearDesde,
      hasta: clearHasta ? null : (hasta ?? state.hasta),
      clearHasta: clearHasta,
      pageNumber: 0,
      orders: [],
      isLoading: true,
    );
    _fetchAndSet(resetList: true);
  }

  Future<void> _fetchAndSet({required bool resetList}) async {
    final response = await repository.getOrdersRestaurant(
      buildOrdersRestaurantQueryParams(state),
    );
    final newOrders = response.content ?? [];
    state = state.copyWith(
      orders: resetList ? newOrders : [...state.orders, ...newOrders],
      last: response.last ?? true,
      isLoading: false,
    );
  }
}

class OrdersRestaurantState {
  final List<OrderRestaurant> orders;
  final bool isLoading;
  final bool last;
  final int pageNumber;
  final int perPage;
  final String sortField;
  final int sortOrder;
  final int? idPuntoVenta;
  final String? nombreCliente;
  final bool? pedidoFacturado;
  final List<String> tipos;
  final List<String> estados;
  final String? desde;
  final String? hasta;

  // UI selection state
  final String selectedTipo;
  final String selectedEstadoPago;

  OrdersRestaurantState({
    required this.orders,
    required this.isLoading,
    required this.last,
    required this.pageNumber,
    required this.perPage,
    required this.sortField,
    required this.sortOrder,
    required this.tipos,
    required this.estados,
    required this.selectedTipo,
    required this.selectedEstadoPago,
    this.idPuntoVenta,
    this.nombreCliente,
    this.pedidoFacturado,
    this.desde,
    this.hasta,
  });

  factory OrdersRestaurantState.initial() {
    return OrdersRestaurantState(
      orders: [],
      isLoading: true,
      last: false,
      pageNumber: 0,
      perPage: 10,
      sortField: 'fecha',
      sortOrder: -1,
      tipos: kAllTipos,
      estados: kAllEstados,
      desde: null,
      hasta: null,
      selectedTipo: 'TODOS',
      selectedEstadoPago: 'PAGADOS',
      pedidoFacturado: true,
    );
  }

  OrdersRestaurantState copyWith({
    List<OrderRestaurant>? orders,
    bool? isLoading,
    bool? last,
    int? pageNumber,
    int? perPage,
    String? sortField,
    int? sortOrder,
    int? idPuntoVenta,
    String? nombreCliente,
    bool? pedidoFacturado,
    bool clearPedidoFacturado = false,
    List<String>? tipos,
    List<String>? estados,
    String? desde,
    bool clearDesde = false,
    String? hasta,
    bool clearHasta = false,
    String? selectedTipo,
    String? selectedEstadoPago,
  }) {
    return OrdersRestaurantState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      last: last ?? this.last,
      pageNumber: pageNumber ?? this.pageNumber,
      perPage: perPage ?? this.perPage,
      sortField: sortField ?? this.sortField,
      sortOrder: sortOrder ?? this.sortOrder,
      idPuntoVenta: idPuntoVenta ?? this.idPuntoVenta,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      pedidoFacturado: clearPedidoFacturado
          ? null
          : (pedidoFacturado ?? this.pedidoFacturado),
      tipos: tipos ?? this.tipos,
      estados: estados ?? this.estados,
      desde: clearDesde ? null : (desde ?? this.desde),
      hasta: clearHasta ? null : (hasta ?? this.hasta),
      selectedTipo: selectedTipo ?? this.selectedTipo,
      selectedEstadoPago: selectedEstadoPago ?? this.selectedEstadoPago,
    );
  }
}
