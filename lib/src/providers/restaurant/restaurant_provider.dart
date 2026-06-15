import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/lounge.dart';
import 'package:teki_app/src/data/models/teki_model/orderRestaurant.dart';
import 'package:teki_app/src/data/models/teki_model/table.dart';
import 'package:teki_app/src/data/repositories/restaurant_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/restaurant_repository.dart';
import 'package:teki_app/src/utils/notifications.dart';

final restaurantProvider =
    StateNotifierProvider<RestaurantNotifier, RestaurantState>(
  (ref) => RestaurantNotifier(
    repository: RestaurantRepositoryImpl(),
  ),
);

class RestaurantNotifier extends StateNotifier<RestaurantState> {
  final RestaurantRepository repository;

  RestaurantNotifier({required this.repository})
      : super(RestaurantState(
          lounges: [],
          tables: [],
          orders: [],
          selectedLoungeId: RestaurantState.kAllSelected,
          pvId: null,
          isLoading: false,
        ));

  Future<void> loadData(int pvId) async {
    state = state.copyWith(isLoading: true);

    // 1. Lounges
    final lounges = await repository.getLounges({'idPuntoVenta': pvId});

    if (lounges.isEmpty) {
      state = state.copyWith(
        lounges: [],
        tables: [],
        orders: [],
        selectedLoungeId: RestaurantState.kAllSelected,
        pvId: pvId,
        isLoading: false,
      );
      return;
    }

    // Default: "Todos" (selectedLoungeId = kAllSelected)
    state = state.copyWith(lounges: lounges, selectedLoungeId: RestaurantState.kAllSelected);

    // 2. Todas las mesas sin filtro de salón
    // 3. Órdenes activas del PV
    final results = await Future.wait([
      repository.getTables({'idPuntoVenta': pvId}),
      repository.getOrders({
        'idPuntoVenta': pvId,
        'tipo': 'LOCAL',
        'estado': ['PENDIENTE', 'PRECUENTA'],
      }),
    ]);

    state = state.copyWith(
      pvId: pvId,
      tables: results[0] as List<Table>,
      orders: results[1] as List<OrderRestaurant>,
      isLoading: false,
    );
  }

  Future<void> selectAll() async {
    final pvId = state.pvId;
    if (pvId == null) return;
    state = state.copyWith(selectedLoungeId: RestaurantState.kAllSelected, tables: [], isLoading: true);

    final results = await Future.wait([
      repository.getTables({'idPuntoVenta': pvId}),
      repository.getOrders({
        'idPuntoVenta': pvId,
        'tipo': 'LOCAL',
        'estado': ['PENDIENTE', 'PRECUENTA'],
      }),
    ]);

    state = state.copyWith(
      tables: results[0] as List<Table>,
      orders: results[1] as List<OrderRestaurant>,
      isLoading: false,
    );
  }

  Future<void> selectLounge(int loungeId) async {
    final pvId = state.pvId;
    if (pvId == null) return;
    state = state.copyWith(selectedLoungeId: loungeId, tables: [], isLoading: true);

    final results = await Future.wait([
      repository.getTables({'idSalon': loungeId}),
      repository.getOrders({
        'idPuntoVenta': pvId,
        'tipo': 'LOCAL',
        'estado': ['PENDIENTE', 'PRECUENTA'],
      }),
    ]);

    state = state.copyWith(
      tables: results[0] as List<Table>,
      orders: results[1] as List<OrderRestaurant>,
      isLoading: false,
    );
  }

  Future<void> reload(int pvId) async {
    if (state.pvId != pvId) state = state.copyWith(pvId: pvId);
    if (state.selectedLoungeId == RestaurantState.kAllSelected) {
      await selectAll();
    } else {
      await selectLounge(state.selectedLoungeId);
    }
  }

  Future<void> deleteOrderChecks(int orderId, int pvId) async {
    try {
      await repository.deleteOrderChecks(orderId);
      successNotification('Precuentas eliminadas');
      await reload(pvId);
    } catch (e) {
      errorNotification(e.toString());
    }
  }

  Future<void> updateOrderStatus(int orderId, String estado, int pvId, {bool updateInventory = true, String? observacion}) async {
    try {
      await repository.updateOrderStatus(orderId, estado, updateInventory: updateInventory, observacion: observacion);
      successNotification('Estado actualizado');
      await reload(pvId);
    } catch (e) {
      errorNotification(e.toString());
    }
  }

  Future<void> updateCommandItemStatus(int commandId, int itemId, String itemStatus, {String? motivoAnulacion}) async {
    final pvId = state.pvId;
    if (pvId == null) return;
    try {
      await repository.updateCommandItemStatus(commandId, itemId, itemStatus, motivoAnulacion: motivoAnulacion);
      await reload(pvId);
    } catch (e) {
      errorNotification(e.toString());
    }
  }

  /// Extrae el ID de mesa de una orden: primero busca en `mesa` raíz,
  /// si es null busca en `comandas[0].pedido.mesa` (back-reference del API).
  int? _mesaIdFromOrder(OrderRestaurant o) {
    if (o.mesa?.id != null) return o.mesa!.id;
    final primeraComanda = o.comandas?.isNotEmpty == true ? o.comandas!.first : null;
    return primeraComanda?.pedido?.mesa?.id;
  }

  List<Table> get tablesWithOrders {
    final mapped = state.tables.map((table) {
      final order = state.orders.firstWhere(
        (o) => _mesaIdFromOrder(o) == table.id,
        orElse: () => OrderRestaurant(),
      );
      if (order.id != null) {
        return Table(
          id: table.id,
          numero: table.numero,
          empresa: table.empresa,
          salon: table.salon,
          multiMesa: table.multiMesa,
          mesaUnida: table.mesaUnida,
          fechaUnion: table.fechaUnion,
          unidoPor: table.unidoPor,
          fechaSeparacion: table.fechaSeparacion,
          separadoPor: table.separadoPor,
          mesaConformada: table.mesaConformada,
          mesasUnidas: table.mesasUnidas,
          mesasUnidasHistorico: table.mesasUnidasHistorico,
          estado: table.estado,
          pedidoActual: order,
          createdOn: table.createdOn,
          createdBy: table.createdBy,
          updatedBy: table.updatedBy,
          updatedOn: table.updatedOn,
          deleteBy: table.deleteBy,
          deletedOn: table.deletedOn,
        );
      }
      return table;
    }).toList();

    if (state.selectedLoungeId == RestaurantState.kAllSelected) {
      mapped.sort((a, b) {
        final aOcupada = a.pedidoActual?.id != null;
        final bOcupada = b.pedidoActual?.id != null;
        if (aOcupada && !bOcupada) return -1;
        if (!aOcupada && bOcupada) return 1;
        final aSalon = a.salon?.id ?? 0;
        final bSalon = b.salon?.id ?? 0;
        return aSalon.compareTo(bSalon);
      });
    }

    return mapped;
  }
}

class RestaurantState {
  // Sentinel que indica "todos los pisos seleccionados"
  static const int kAllSelected = -1;

  final List<Lounge> lounges;
  final List<Table> tables;
  final List<OrderRestaurant> orders;
  // -1 (kAllSelected) = "Todos", cualquier otro valor = id del salón
  final int selectedLoungeId;
  final int? pvId;
  final bool isLoading;

  RestaurantState({
    required this.lounges,
    required this.tables,
    required this.orders,
    required this.selectedLoungeId,
    required this.pvId,
    required this.isLoading,
  });

  RestaurantState copyWith({
    List<Lounge>? lounges,
    List<Table>? tables,
    List<OrderRestaurant>? orders,
    int? selectedLoungeId,
    int? pvId,
    bool? isLoading,
  }) =>
      RestaurantState(
        lounges: lounges ?? this.lounges,
        tables: tables ?? this.tables,
        orders: orders ?? this.orders,
        selectedLoungeId: selectedLoungeId ?? this.selectedLoungeId,
        pvId: pvId ?? this.pvId,
        isLoading: isLoading ?? this.isLoading,
      );
}
