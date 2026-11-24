import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/check.dart';
import 'package:teki_app/src/data/repositories/restaurant_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/restaurant_repository.dart';

enum TipoPedidoFilter { todos, mesa, pedido, envios }

/// Filtro de estado de pago (con 'Todos', como pide la vista combinada).
enum EstadoPagoFilter { todos, pendientes, pagados }

extension EstadoPagoFilterX on EstadoPagoFilter {
  String get label {
    switch (this) {
      case EstadoPagoFilter.todos:
        return 'Todos';
      case EstadoPagoFilter.pendientes:
        return 'Pendientes';
      case EstadoPagoFilter.pagados:
        return 'Pagados';
    }
  }
}

extension TipoPedidoFilterX on TipoPedidoFilter {
  String get label {
    switch (this) {
      case TipoPedidoFilter.todos:
        return 'Todos';
      case TipoPedidoFilter.mesa:
        return 'Mesa';
      case TipoPedidoFilter.pedido:
        return 'Pedido';
      case TipoPedidoFilter.envios:
        return 'Envíos';
    }
  }

  List<String> get tipos {
    switch (this) {
      case TipoPedidoFilter.todos:
        return [
          'LOCAL',
          'PEDIDO_LOCAL',
          'PEDIDO_LOCAL_INTERNO',
          'PEDIDO_FORANEO',
          'PEDIDO_ONLINE',
        ];
      case TipoPedidoFilter.mesa:
        return ['LOCAL'];
      case TipoPedidoFilter.pedido:
        return ['PEDIDO_LOCAL', 'PEDIDO_LOCAL_INTERNO'];
      case TipoPedidoFilter.envios:
        return ['PEDIDO_FORANEO', 'PEDIDO_ONLINE'];
    }
  }
}

final cobradorProvider =
    StateNotifierProvider<CobradorNotifier, CobradorState>(
  (ref) => CobradorNotifier(repository: RestaurantRepositoryImpl()),
);

class CobradorNotifier extends StateNotifier<CobradorState> {
  final RestaurantRepository repository;

  CobradorNotifier({required this.repository})
      : super(CobradorState(
          checks: [],
          selectedDate: DateTime.now(),
          tipoPedidoFilter: TipoPedidoFilter.todos,
          pagadoFilter: EstadoPagoFilter.pendientes,
          isLoading: false,
        ));

  Future<void> init(int pvId) async {
    await _load(pvId);
  }

  Future<void> _load(int pvId) async {
    state = state.copyWith(isLoading: true);
    final d = state.selectedDate;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
    final checks = await repository.getChecks({
      // 'Todos' no manda el filtro: el backend devuelve pagadas y pendientes.
      if (state.pagadoFilter != EstadoPagoFilter.todos)
        'pagado': state.pagadoFilter == EstadoPagoFilter.pagados,
      'idPuntoVenta': pvId,
      'fecha': dateStr,
      'tipoPedido': state.tipoPedidoFilter.tipos,
    });
    state = state.copyWith(checks: checks, isLoading: false);
  }

  Future<void> setDate(DateTime date, int pvId) async {
    state = state.copyWith(selectedDate: date);
    await _load(pvId);
  }

  Future<void> setTipoPedido(TipoPedidoFilter filter, int pvId) async {
    state = state.copyWith(tipoPedidoFilter: filter);
    await _load(pvId);
  }

  Future<void> setEstadoPago(EstadoPagoFilter filtro, int pvId) async {
    state = state.copyWith(pagadoFilter: filtro);
    await _load(pvId);
  }

  Future<Check> getCheckById(int id) => repository.getCheckById(id);
}

class CobradorState {
  final List<Check> checks;
  final DateTime selectedDate;
  final TipoPedidoFilter tipoPedidoFilter;
  final EstadoPagoFilter pagadoFilter;
  final bool isLoading;

  CobradorState({
    required this.checks,
    required this.selectedDate,
    required this.tipoPedidoFilter,
    required this.pagadoFilter,
    required this.isLoading,
  });

  CobradorState copyWith({
    List<Check>? checks,
    DateTime? selectedDate,
    TipoPedidoFilter? tipoPedidoFilter,
    EstadoPagoFilter? pagadoFilter,
    bool? isLoading,
  }) =>
      CobradorState(
        checks: checks ?? this.checks,
        selectedDate: selectedDate ?? this.selectedDate,
        tipoPedidoFilter: tipoPedidoFilter ?? this.tipoPedidoFilter,
        pagadoFilter: pagadoFilter ?? this.pagadoFilter,
        isLoading: isLoading ?? this.isLoading,
      );
}
