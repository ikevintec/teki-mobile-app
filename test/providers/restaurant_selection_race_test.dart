import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/lounge.dart';
import 'package:teki_app/src/data/models/teki_model/order_restaurant.dart';
import 'package:teki_app/src/data/models/teki_model/table.dart';
import 'package:teki_app/src/domain/repositories/restaurant_repository.dart';
import 'package:teki_app/src/providers/restaurant/restaurant_provider.dart';

class _Request {
  final Map<String, dynamic> params;
  final result = Completer<List<Table>>();
  _Request(this.params);
  void complete(int id) => result.complete([Table(id: id)]);
}

class _SlowRepository implements RestaurantRepository {
  bool hold = false;
  bool holdLounges = false;
  final loungeRequests = <Completer<List<Lounge>>>[];
  final requests = <_Request>[];
  @override
  Future<List<Lounge>> getLounges(Map<String, dynamic> params) {
    if (holdLounges) {
      final result = Completer<List<Lounge>>();
      loungeRequests.add(result);
      return result.future;
    }
    return Future.value([Lounge(id: 1), Lounge(id: 2)]);
  }

  @override
  Future<List<OrderRestaurant>> getOrders(Map<String, dynamic> params) async =>
      [];
  @override
  Future<List<Table>> getTables(Map<String, dynamic> params) {
    if (!hold) return Future.value([]);
    final request = _Request(params);
    requests.add(request);
    return request.result.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _SlowRepository repo;
  late RestaurantNotifier notifier;
  setUp(() async {
    repo = _SlowRepository();
    notifier = RestaurantNotifier(repository: repo);
    await notifier.loadData(1);
    repo.hold = true;
  });
  tearDown(() {
    if (notifier.mounted) notifier.dispose();
  });

  test(
    'respuesta de salón anterior no reemplaza la selección reciente',
    () async {
      final old = notifier.selectLounge(1);
      final current = notifier.selectLounge(2);
      repo.requests[1].complete(22);
      await current;
      repo.requests[0].complete(11);
      await old;
      expect(notifier.state.selectedLoungeId, 2);
      expect(notifier.state.tables.single.id, 22);
      expect(notifier.state.isLoading, isFalse);
    },
  );

  test(
    'volver al mismo salón tampoco acepta la primera respuesta antigua',
    () async {
      final first = notifier.selectLounge(1);
      final second = notifier.selectLounge(2);
      final third = notifier.selectLounge(1);
      repo.requests[2].complete(33);
      await third;
      repo.requests[0].complete(11);
      await first;
      repo.requests[1].complete(22);
      await second;
      expect(notifier.state.selectedLoungeId, 1);
      expect(notifier.state.tables.single.id, 33);
    },
  );

  test('Todos y salón compiten con la misma secuencia de respuestas', () async {
    final all = notifier.selectAll();
    final lounge = notifier.selectLounge(2);
    repo.requests[1].complete(22);
    await lounge;
    repo.requests[0].complete(11);
    await all;
    expect(notifier.state.selectedLoungeId, 2);
    expect(notifier.state.tables.single.id, 22);
    final oldLounge = notifier.selectLounge(1);
    final newAll = notifier.selectAll();
    repo.requests[3].complete(44);
    await newAll;
    repo.requests[2].complete(33);
    await oldLounge;
    expect(notifier.state.selectedLoungeId, RestaurantState.kAllSelected);
    expect(notifier.state.tables.single.id, 44);
  });

  test('cambio de sede invalida la respuesta anterior', () async {
    final old = notifier.selectAll();
    final current = notifier.reload(2);
    repo.requests[1].complete(22);
    await current;
    repo.requests[0].complete(11);
    await old;
    expect(repo.requests[1].params['idPuntoVenta'], 2);
    expect(notifier.state.pvId, 2);
    expect(notifier.state.tables.single.id, 22);
  });

  test(
    'refresh silencioso no deja loader pendiente ni acepta consulta anterior',
    () async {
      final old = notifier.selectLounge(1);
      final current = notifier.reload(1, silent: true);
      repo.requests[1].complete(22);
      await current;
      repo.requests[0].complete(11);
      await old;
      expect(notifier.state.tables.single.id, 22);
      expect(notifier.state.isLoading, isFalse);
    },
  );

  test('carga inicial tardía no pisa una selección iniciada después', () async {
    final old = notifier.loadData(1);
    await Future<void>.delayed(Duration.zero);
    final current = notifier.selectLounge(2);
    repo.requests[1].complete(22);
    await current;
    repo.requests[0].complete(11);
    await old;
    expect(notifier.state.selectedLoungeId, 2);
    expect(notifier.state.tables.single.id, 22);
  });

  test(
    'refresh de socket durante carga inicial conserva los salones recibidos',
    () async {
      repo.holdLounges = true;
      final initial = notifier.loadData(1);
      final socket = notifier.reload(1, silent: true);
      repo.requests.single.complete(22);
      await socket;
      repo.loungeRequests.single.complete([Lounge(id: 1), Lounge(id: 2)]);
      await initial;
      expect(notifier.state.lounges.map((lounge) => lounge.id), [1, 2]);
      expect(notifier.state.tables.single.id, 22);
      expect(notifier.state.isLoading, isFalse);
    },
  );

  for (final pv in [1, 2]) {
    test(
      'carga antigua de salones no reemplaza la nueva en sede $pv',
      () async {
        repo.holdLounges = true;
        final old = notifier.loadData(1);
        final current = notifier.loadData(pv);
        repo.loungeRequests[1].complete([Lounge(id: 2)]);
        await Future<void>.delayed(Duration.zero);
        repo.requests.single.complete(22);
        await current;
        repo.loungeRequests[0].complete([Lounge(id: 1)]);
        await old;
        expect(notifier.state.lounges.single.id, 2);
        expect(notifier.state.pvId, pv);
        expect(notifier.state.tables.single.id, 22);
      },
    );
  }

  test('destruir provider descarta la respuesta pendiente sin error', () async {
    final pending = notifier.selectLounge(1);
    notifier.dispose();
    repo.requests.single.complete(11);
    await expectLater(pending, completes);
  });
}
