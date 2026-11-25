import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/response/order_restaurant_response.dart';
import 'package:teki_app/src/domain/repositories/orders_restaurant_repository.dart';
import 'package:teki_app/src/providers/orders_restaurant/orders_restaurant_provider.dart';

class _Orders implements OrdersRestaurantRepository {
  final queries = <Map<String, dynamic>>[];
  @override
  Future<OrderRestaurantResponse> getOrdersRestaurant(
    Map<String, dynamic> params,
  ) async {
    queries.add(Map.of(params));
    final orders =
        [
          {'id': 1, 'estado': 'PENDIENTE', 'tipo': 'LOCAL', 'pagado': true},
          {
            'id': 2,
            'estado': 'PREPARADO',
            'tipo': 'PEDIDO_LOCAL',
            'pagado': false,
          },
          {
            'id': 3,
            'estado': 'PRECUENTA',
            'tipo': 'PEDIDO_LOCAL_INTERNO',
            'pagado': true,
          },
          {
            'id': 4,
            'estado': 'CANCELADO',
            'tipo': 'PEDIDO_FORANEO',
            'pagado': false,
          },
          {
            'id': 5,
            'estado': 'FINALIZADO',
            'tipo': 'PEDIDO_ONLINE',
            'pagado': false,
          },
        ].where(
          (o) =>
              (params['estado'] as List).contains(o['estado']) &&
              (params['tipo'] as List).contains(o['tipo']) &&
              (!params.containsKey('pedidoFacturado') ||
                  params['pedidoFacturado'] == o['pagado']),
        );
    return OrderRestaurantResponse.fromJson({
      'content': orders.toList(),
      'last': true,
      'totalElements': orders.length,
    });
  }
}

class _PendingOrders implements OrdersRestaurantRepository {
  final pending = <Completer<OrderRestaurantResponse>>[];
  @override
  Future<OrderRestaurantResponse> getOrdersRestaurant(
    Map<String, dynamic> params,
  ) {
    final request = Completer<OrderRestaurantResponse>();
    pending.add(request);
    return request.future;
  }

  void complete(int index, int id, {bool last = true}) =>
      pending[index].complete(
        OrderRestaurantResponse.fromJson({
          'content': [
            {'id': id},
          ],
          'last': last,
        }),
      );
}

void main() {
  late _Orders repo;
  late OrdersRestaurantNotifier notifier;
  setUp(() {
    repo = _Orders();
    notifier = OrdersRestaurantNotifier(repository: repo);
  });
  tearDown(() => notifier.dispose());

  test(
    'respuesta antigua del historial no reemplaza los activos actuales',
    () async {
      final deferred = _PendingOrders();
      final current = OrdersRestaurantNotifier(repository: deferred);
      addTearDown(current.dispose);
      final initial = current.initialize(606);
      deferred.complete(0, 1);
      await initial;
      current.updateEstados(['CANCELADO']);
      current.updateEstados(kActiveEstados);
      deferred.complete(2, 1);
      await Future<void>.delayed(Duration.zero);
      deferred.complete(1, 4);
      await Future<void>.delayed(Duration.zero);
      expect(current.state.estados, kActiveEstados);
      expect(current.state.orders.map((o) => o.id), [1]);
    },
  );
  test('página anterior no se agrega después de cambiar filtros', () async {
    final deferred = _PendingOrders();
    final current = OrdersRestaurantNotifier(repository: deferred);
    addTearDown(current.dispose);
    final initial = current.initialize(606);
    deferred.complete(0, 1, last: false);
    await initial;
    final page = current.loadNextPage();
    current.updateEstados(['CANCELADO']);
    deferred.complete(2, 4);
    await Future<void>.delayed(Duration.zero);
    deferred.complete(1, 2);
    await page;
    expect(current.state.orders.map((o) => o.id), [4]);
    expect(current.state.pageNumber, 0);
  });
  test('carga antigua de otra sede no reemplaza la nueva sede', () async {
    final deferred = _PendingOrders();
    final current = OrdersRestaurantNotifier(repository: deferred);
    addTearDown(current.dispose);
    final oldOffice = current.initialize(606);
    final newOffice = current.initialize(607);
    deferred.complete(1, 7);
    await newOffice;
    deferred.complete(0, 6);
    await oldOffice;
    expect(current.state.idPuntoVenta, 607);
    expect(current.state.orders.single.id, 7);
  });

  test(
    'primera consulta incluye activos pagados y no pagados, sin historial',
    () async {
      await notifier.initialize(606);
      expect(notifier.state.orders.map((o) => o.id), [1, 2, 3]);
      final query = repo.queries.single;
      expect(query['estado'], ['PENDIENTE', 'PREPARADO', 'PRECUENTA']);
      expect(query['tipo'], kAllTipos);
      expect(query['idPuntoVenta'], 606);
      expect(query['borradores'], false);
      expect(query['sortField'], 'fecha');
      expect(query['sortOrder'], -1);
      expect(query.containsKey('pedidoFacturado'), false);
      expect(query.containsKey('desde'), false);
      expect(query.containsKey('hasta'), false);
      expect(notifier.state.selectedEstadoPago, 'TODOS');
    },
  );
  test('historial sigue accesible al seleccionar sus estados', () async {
    await notifier.initialize(606);
    notifier.updateEstados(['CANCELADO', 'FINALIZADO']);
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.orders.map((o) => o.id), [4, 5]);
  });
  test('pago Todos y valor vacío quitan la restricción anterior', () async {
    await notifier.initialize(606);
    for (final all in ['TODOS', null]) {
      notifier.updateEstadoPago('PAGADOS');
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.orders.map((o) => o.id), [1, 3]);
      notifier.updateEstadoPago(all);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.orders.map((o) => o.id), [1, 2, 3]);
      expect(notifier.state.selectedEstadoPago, 'TODOS');
      expect(repo.queries.last.containsKey('pedidoFacturado'), false);
    }
  });
  test('refrescar conserva una selección explícita de histórico', () async {
    await notifier.initialize(606);
    notifier.updateEstados(['CANCELADO']);
    await Future<void>.delayed(Duration.zero);
    await notifier.initialize(606);
    expect(notifier.state.orders.single.id, 4);
    expect(repo.queries.last['estado'], ['CANCELADO']);
  });
  test('Activos no marca filtros extra; histórico, todos o fechas sí', () {
    final state = OrdersRestaurantState.initial();
    expect(state.hasAdvancedFilters, false);
    expect(
      state
          .copyWith(estados: ['PRECUENTA', 'PENDIENTE', 'PREPARADO'])
          .hasAdvancedFilters,
      false,
    );
    expect(state.copyWith(estados: ['CANCELADO']).hasAdvancedFilters, true);
    expect(state.copyWith(estados: kAllEstados).hasAdvancedFilters, true);
    expect(state.copyWith(desde: '24-11-2026').hasAdvancedFilters, true);
  });
  test(
    'selección vacía permite consultar todos los estados explícitamente',
    () async {
      await notifier.initialize(606);
      notifier.updateEstados([]);
      await Future<void>.delayed(Duration.zero);
      expect(repo.queries.last['estado'], kAllEstados);
      expect(notifier.state.orders, hasLength(5));
      expect(notifier.state.hasAdvancedFilters, true);
    },
  );
}
