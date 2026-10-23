import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/response/inventory_detail_page.dart';
import 'package:teki_app/src/providers/inventory/inventory_details_provider.dart';

void main() {
  test(
    'solicita una página a la vez y deja de consultar al llegar al final',
    () async {
      final first = Completer<InventoryDetailPage<int>>();
      final requests = <int>[];
      final notifier = InventoryDetailsNotifier<int>(
        fetch: (page, size, token) {
          requests.add(page);
          expect(size, 15);
          return page == 0
              ? first.future
              : Future.value(const InventoryDetailPage(items: [2], last: true));
        },
      );
      addTearDown(notifier.dispose);
      expect(requests, isEmpty);
      final loading = notifier.loadNextPage();
      await notifier.loadNextPage();
      expect(requests, [0]);
      first.complete(const InventoryDetailPage(items: [1], last: false));
      await loading;
      await notifier.loadNextPage();
      await notifier.loadNextPage();
      expect(requests, [0, 1]);
      expect(notifier.state.items, [1, 2]);
    },
  );

  test(
    'el reintento conserva los datos y repite la página que falló',
    () async {
      final requests = <int>[];
      var fail = true;
      final notifier = InventoryDetailsNotifier<int>(
        fetch: (page, size, token) async {
          requests.add(page);
          if (page == 1 && fail) throw Exception('offline');
          return InventoryDetailPage(items: [page], last: page == 1);
        },
      );
      addTearDown(notifier.dispose);
      await notifier.loadNextPage();
      await notifier.loadNextPage();
      expect(notifier.state.items, [0]);
      expect(notifier.state.error, isNotNull);
      fail = false;
      await notifier.loadNextPage();
      expect(requests, [0, 1, 1]);
      expect(notifier.state.items, [0, 1]);
      expect(notifier.state.error, isNull);
    },
  );

  test('al cerrar cancela la petición e ignora una respuesta tardía', () async {
    final response = Completer<InventoryDetailPage<int>>();
    late CancelToken requestToken;
    final notifier = InventoryDetailsNotifier<int>(
      fetch: (page, size, token) {
        requestToken = token;
        return response.future;
      },
    );
    final loading = notifier.loadNextPage();
    notifier.dispose();
    expect(requestToken.isCancelled, isTrue);
    response.complete(const InventoryDetailPage(items: [1], last: true));
    await expectLater(loading, completes);
  });

  test(
    'un error inicial se puede reintentar sin saltarse la primera página',
    () async {
      var fail = true;
      final notifier = InventoryDetailsNotifier<int>(
        fetch: (page, size, token) async {
          expect(page, 0);
          if (fail) throw Exception('offline');
          return const InventoryDetailPage(items: [], last: true);
        },
      );
      addTearDown(notifier.dispose);
      await notifier.loadNextPage();
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNotNull);
      fail = false;
      await notifier.loadNextPage();
      expect(notifier.state.last, isTrue);
      expect(notifier.state.error, isNull);
    },
  );
}
