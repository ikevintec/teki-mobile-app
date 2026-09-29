import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/response/online_order_response.dart';
import 'package:teki_app/src/data/models/teki_model/online_order.dart';
import 'package:teki_app/src/domain/repositories/online_order_repository.dart';
import 'package:teki_app/src/providers/online_orders/online_orders_provider.dart';

class _FakeOnlineOrderRepository implements OnlineOrderRepository {
  final calls = <Map<String, dynamic>>[];

  @override
  Future<OnlineOrderResponse> getOrders(Map<String, dynamic> params) async {
    calls.add(Map<String, dynamic>.from(params));
    final page = params['pageNumber'] as int;
    if (page == 0) {
      return const OnlineOrderResponse(
        content: [
          OnlineOrder(id: 1, estado: 'PENDIENTE'),
          OnlineOrder(id: 2, estado: 'PENDIENTE'),
        ],
        number: 0,
        totalPages: 2,
        totalElements: 3,
        last: false,
      );
    }
    return const OnlineOrderResponse(
      content: [
        OnlineOrder(id: 2, estado: 'PENDIENTE'),
        OnlineOrder(id: 3, estado: 'ACEPTADO'),
      ],
      number: 1,
      totalPages: 2,
      totalElements: 3,
      last: true,
    );
  }

  @override
  Future<OnlineOrder> getOrder(int id) async => OnlineOrder(id: id);

  @override
  Future<OnlineOrder> changeStatus(int id, String status) async =>
      OnlineOrder(id: id, estado: status);
}

void main() {
  test('pagina, evita duplicados y reload conserva los filtros', () async {
    final repository = _FakeOnlineOrderRepository();
    final container = ProviderContainer(
      overrides: [onlineOrderRepositoryProvider.overrideWithValue(repository)],
    );
    final subscription = container.listen(
      onlineOrdersProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(() {
      subscription.close();
      container.dispose();
    });

    final notifier = container.read(onlineOrdersProvider.notifier);
    await notifier.loadFirstPage();
    expect(container.read(onlineOrdersProvider).orders.map((e) => e.id), [
      1,
      2,
    ]);

    await notifier.loadMore();
    final paged = container.read(onlineOrdersProvider);
    expect(paged.orders.map((e) => e.id), [1, 2, 3]);
    expect(paged.hasMore, isFalse);

    await notifier.applyFilters(
      tipo: 'MENU',
      estado: 'PENDIENTE',
      cliente: 'Ana',
      numeroPedido: '0012',
    );
    await notifier.refresh();

    final lastCall = repository.calls.last;
    expect(lastCall['pageNumber'], 0);
    expect(lastCall['tipo'], 'MENU');
    expect(lastCall['estado'], 'PENDIENTE');
    expect(lastCall['cliente'], 'Ana');
    expect(lastCall['numeroPedido'], '0012');
  });
}
