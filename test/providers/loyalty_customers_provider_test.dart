import 'package:teki_app/src/data/models/teki_model/loyalty_coupon.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_customer.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_page.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/loyalty/loyalty_provider.dart';
import 'package:teki_app/src/providers/loyalty/loyalty_customers_provider.dart';
import 'package:teki_app/src/providers/loyalty/loyalty_page_notifier.dart';
import '../support/loyalty_fixture.dart';
import '../support/loyalty_p2_fixture.dart';

class _Delayed extends DemoLoyaltyP2Repository {
  final requests = <Completer<LoyaltyPage<LoyaltyCustomer>>>[];
  final tokens = <CancelToken>[];
  @override
  Future<LoyaltyPage<LoyaltyCustomer>> getCustomers(
    int cardId, {
    String filter = '',
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) {
    tokens.add(cancelToken!);
    final request = Completer<LoyaltyPage<LoyaltyCustomer>>();
    requests.add(request);
    return request.future;
  }
}

class _WrongCoupon extends DemoLoyaltyP2Repository {
  @override
  Future<LoyaltyPage<LoyaltyCoupon>> getCoupons(
    int enrollmentId, {
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) async => const LoyaltyPage(
    items: [
      LoyaltyCoupon(
        id: 1,
        enrollmentId: 21,
        cardId: 2,
        name: 'Cupón de otra tarjeta',
      ),
    ],
    total: 1,
    hasMore: false,
  );
}

void main() {
  const cardKey = (companyId: 1, cardId: 1);
  const memberKey = (companyId: 1, cardId: 1, enrollmentId: 11);
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  ProviderContainer container(
    DemoLoyaltyP2Repository repo, {
    LoyaltySessionNotifier? session,
  }) => ProviderContainer(
    overrides: [
      sesionProvider.overrideWith(
        (ref) =>
            session ?? LoyaltySessionNotifier(loyaltySession(roles: p2Roles)),
      ),
      loyaltyRepositoryProvider.overrideWithValue(repo),
    ],
  );

  test('permiso de tarjetas no concede clientes ni cupones', () async {
    final repo = DemoLoyaltyP2Repository();
    final c = container(
      repo,
      session: LoyaltySessionNotifier(loyaltySession()),
    );
    addTearDown(c.dispose);
    await c.read(loyaltyCustomersProvider(cardKey).notifier).load();
    await c.read(loyaltyMovementsProvider(memberKey).notifier).load();
    await c.read(loyaltyCouponsProvider(memberKey).notifier).load();
    expect(await c.read(loyaltyCustomerProvider(memberKey).future), null);
    expect(repo.customerCalls, isEmpty);
    expect(repo.enrollmentCalls, isEmpty);
    expect(repo.couponCalls, isEmpty);
    expect(repo.movementCalls, isEmpty);
  });

  test('clientes y cupones conservan permisos independientes', () async {
    final repo = DemoLoyaltyP2Repository();
    final session = loyaltySession(
      roles: ['LOYALTI_CONFIG_VER', 'LOYALTI_CUSTOMERS_VER'],
    );
    expect(canViewLoyaltyCustomers(session), true);
    expect(canViewLoyaltyCoupons(session), false);
    final c = container(repo, session: LoyaltySessionNotifier(session));
    addTearDown(c.dispose);
    await c.read(loyaltyCouponsProvider(memberKey).notifier).load();
    expect(repo.couponCalls, isEmpty);
    expect(repo.enrollmentCalls, isEmpty);
  });

  test(
    'mismo Customer conserva dos inscripciones y saldos distintos',
    () async {
      final repo = DemoLoyaltyP2Repository();
      final c = container(repo);
      addTearDown(c.dispose);
      final first = await c.read(loyaltyCustomerProvider(memberKey).future);
      final second = await c.read(
        loyaltyCustomerProvider((
          companyId: 1,
          cardId: 2,
          enrollmentId: 21,
        )).future,
      );
      expect(first!.customer.customerId, second!.customer.customerId);
      expect(first.customer.availablePoints, 40);
      expect(second.customer.availablePoints, 90);
      expect(repo.enrollmentCalls, [11, 21]);
    },
  );

  test(
    'inscripción de otro programa se rechaza antes de consultar movimientos',
    () async {
      final repo = DemoLoyaltyP2Repository();
      final c = container(repo);
      addTearDown(c.dispose);
      const wrong = (companyId: 1, cardId: 2, enrollmentId: 11);
      await expectLater(
        c.read(loyaltyCustomerProvider(wrong).future),
        throwsException,
      );
      final sub = c.listen(loyaltyMovementsProvider(wrong), (_, _) {});
      addTearDown(sub.close);
      await settle();
      expect(
        c.read(loyaltyMovementsProvider(wrong)).error,
        contains('no corresponde'),
      );
      expect(repo.movementCalls, isEmpty);
    },
  );

  test(
    'cambiar empresa cancela página anterior y no consulta con la clave antigua',
    () async {
      final repo = _Delayed();
      final session = LoyaltySessionNotifier(loyaltySession(roles: p2Roles));
      final c = container(repo, session: session);
      addTearDown(c.dispose);
      final sub = c.listen(loyaltyCustomersProvider(cardKey), (_, _) {});
      addTearDown(sub.close);
      await settle();
      expect(repo.requests.length, 1);
      session.replace(loyaltySession(companyId: 2, roles: p2Roles));
      await settle();
      expect(repo.tokens.single.isCancelled, true);
      repo.requests.single.complete(
        const LoyaltyPage(items: [p2Member], total: 1, hasMore: false),
      );
      await settle();
      expect(c.read(loyaltyCustomersProvider(cardKey)).items, isEmpty);
      expect(repo.requests.length, 1);
    },
  );

  test(
    'cerrar proveedor cancela petición y acepta una respuesta tardía sin escrituras',
    () async {
      final repo = _Delayed();
      final c = container(repo);
      final sub = c.listen(loyaltyCustomersProvider(cardKey), (_, _) {});
      await settle();
      sub.close();
      c.dispose();
      expect(repo.tokens.single.isCancelled, true);
      repo.requests.single.complete(
        const LoyaltyPage(items: [p2Member], total: 1, hasMore: false),
      );
      await settle();
    },
  );

  test(
    'búsqueda espera 350 ms, cancela lo anterior y descarta respuestas antiguas',
    () async {
      final requests =
          <
            ({
              String filter,
              CancelToken token,
              Completer<LoyaltyPage<int>> result,
            })
          >[];
      final notifier = LoyaltyPageNotifier<int>(
        enabled: true,
        loader: (page, filter, token) {
          final result = Completer<LoyaltyPage<int>>();
          requests.add((filter: filter, token: token, result: result));
          return result.future;
        },
      );
      addTearDown(notifier.dispose);
      final initial = notifier.load();
      notifier.search(' A ');
      notifier.search(' B ');
      expect(requests.single.token.isCancelled, true);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(requests.length, 2);
      expect(requests.last.filter, 'B');
      requests.last.result.complete(
        const LoyaltyPage(items: [2], total: 81, hasMore: true),
      );
      await settle();
      requests.first.result.complete(
        const LoyaltyPage(items: [1], total: 1, hasMore: false),
      );
      await initial;
      expect(notifier.state.items, [2]);
      expect(notifier.state.total, 81);
      expect(notifier.state.filter, ' B ');
      expect(notifier.state.hasMore, true);
    },
  );

  test(
    'fallo al cargar más conserva página y permite reintentar sin saltarla',
    () async {
      final pages = <int>[];
      bool fail = true;
      final notifier = LoyaltyPageNotifier<int>(
        enabled: true,
        loader: (page, filter, token) async {
          pages.add(page);
          if (page == 1 && fail) throw Exception('Sin conexión');
          return LoyaltyPage(items: [page + 1], total: 2, hasMore: page == 0);
        },
      );
      addTearDown(notifier.dispose);
      await notifier.load();
      await notifier.loadMore();
      expect(notifier.state.items, [1]);
      expect(notifier.state.page, 0);
      expect(notifier.state.error, 'Sin conexión');
      expect(notifier.state.loaded, true);
      fail = false;
      await notifier.loadMore();
      expect(pages, [0, 1, 1]);
      expect(notifier.state.items, [1, 2]);
      expect(notifier.state.hasMore, false);
      await notifier.loadMore();
      expect(pages.length, 3);
    },
  );

  test('dos cargas de la misma página no duplican solicitudes', () async {
    final pending = Completer<LoyaltyPage<int>>();
    var calls = 0;
    final notifier = LoyaltyPageNotifier<int>(
      enabled: true,
      loader: (page, filter, token) {
        calls++;
        return pending.future;
      },
    );
    final first = notifier.load();
    await notifier.loadMore();
    expect(calls, 1);
    notifier.dispose();
    pending.complete(const LoyaltyPage(items: [], total: 0, hasMore: false));
    await first;
  });
  test(
    'rechaza cupones de otra inscripción aunque compartan Customer',
    () async {
      final c = container(_WrongCoupon());
      addTearDown(c.dispose);
      final sub = c.listen(loyaltyCouponsProvider(memberKey), (_, _) {});
      addTearDown(sub.close);
      await settle();
      expect(c.read(loyaltyCouponsProvider(memberKey)).items, isEmpty);
      expect(
        c.read(loyaltyCouponsProvider(memberKey)).error,
        contains('no corresponden'),
      );
    },
  );
}
