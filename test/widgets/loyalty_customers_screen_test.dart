import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_customer.dart';
import 'package:teki_app/src/presentation/screens/loyalty/loyalty_cards_screen.dart';
import 'package:teki_app/src/presentation/screens/loyalty/loyalty_customers_screen.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/loyalty/loyalty_provider.dart';
import 'package:teki_app/src/shared/services/loyalty_link_service.dart';
import '../support/loyalty_fixture.dart';
import '../support/loyalty_p2_fixture.dart';

void main() {
  const key = (companyId: 1, cardId: 1, enrollmentId: 11);
  Future<void> mount(
    WidgetTester tester,
    Widget screen, {
    DemoLoyaltyP2Repository? repo,
    LoyaltySessionNotifier? session,
    double scale = 1,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sesionProvider.overrideWith(
            (ref) =>
                session ??
                LoyaltySessionNotifier(loyaltySession(roles: p2Roles)),
          ),
          loyaltyRepositoryProvider.overrideWithValue(
            repo ?? DemoLoyaltyP2Repository(),
          ),
          loyaltyLinkServiceProvider.overrideWithValue(
            const LoyaltyLinkService('https://example.com'),
          ),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, String text) =>
      tester.scrollUntilVisible(
        find.text(text),
        160,
        scrollable: find
            .descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Scrollable),
            )
            .first,
      );

  testWidgets('abre clientes desde tarjeta y busca por el programa elegido', (
    tester,
  ) async {
    final repo = DemoLoyaltyP2Repository();
    await mount(
      tester,
      const LoyaltyCardScreen(companyId: 1, cardId: 1),
      repo: repo,
    );
    await scrollTo(tester, 'Clientes de esta tarjeta');
    await tester.tap(find.text('Clientes de esta tarjeta'));
    await tester.pumpAndSettle();
    expect(find.text('2 clientes'), findsOneWidget);
    expect(find.text('Documento: ••••5678'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Luis');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('1 cliente encontrado'), findsOneWidget);
    expect(find.text('Luis de prueba'), findsOneWidget);
    expect(find.text('María de prueba'), findsNothing);
    expect(repo.customerCalls.every((c) => c.cardId == 1), true);
    expect(repo.customerCalls.last.filter, 'Luis');
    await tester.enterText(find.byType(TextField), '');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('2 clientes'), findsOneWidget);
    expect(find.text('María de prueba'), findsOneWidget);
  });

  testWidgets(
    'el total mostrado procede del servidor y no del tamaño de la página',
    (tester) async {
      final repo = DemoLoyaltyP2Repository()..totalOverride = 81;
      await mount(
        tester,
        const LoyaltyCustomersScreen(companyId: 1, card: p2Card),
        repo: repo,
      );
      expect(find.text('81 clientes'), findsOneWidget);
      expect(find.text('2 clientes'), findsNothing);
      expect(find.text('Cargar más'), findsOneWidget);
    },
  );

  testWidgets(
    'separa sellos históricos, ciclo, puntos disponibles e históricos',
    (tester) async {
      await mount(tester, const LoyaltyCustomerScreen(customerKey: key));
      expect(find.text('María de prueba'), findsOneWidget);
      expect(find.text('Recargas de prueba'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('Avance del ciclo: 4 de 10 sellos'), findsOneWidget);
      expect(find.text('40'), findsOneWidget);
      await scrollTo(tester, 'Puntos acumulados históricos');
      expect(find.text('50'), findsOneWidget);
      expect(find.text('María de prueba').hitTestable(), findsOneWidget);
      expect(find.text('Premio disponible'), findsNothing);
    },
  );

  testWidgets(
    'mismo cliente en otra tarjeta muestra otro saldo y solo sus unidades',
    (tester) async {
      await mount(
        tester,
        const LoyaltyCustomerScreen(
          customerKey: (companyId: 1, cardId: 2, enrollmentId: 21),
        ),
      );
      expect(find.text('90'), findsOneWidget);
      expect(find.text('Puntos de prueba'), findsOneWidget);
      expect(find.text('Sellos acumulados (histórico)'), findsNothing);
      expect(find.text('40'), findsNothing);
    },
  );

  for (final stamps in [10, 20]) {
    testWidgets('$stamps sellos inicia otro ciclo sin anunciar un premio', (
      tester,
    ) async {
      final repo = DemoLoyaltyP2Repository(
        enrollments: [
          LoyaltyCustomer(
            id: 11,
            cardId: 1,
            name: 'María de prueba',
            cardName: 'Recargas de prueba',
            stamps: stamps,
            active: true,
          ),
        ],
      );
      await mount(
        tester,
        const LoyaltyCustomerScreen(customerKey: key),
        repo: repo,
      );
      expect(find.text('Avance del ciclo: 0 de 10 sellos'), findsOneWidget);
      expect(find.text('Premio disponible'), findsNothing);
      expect(repo.couponCalls, isEmpty);
    });
  }

  testWidgets(
    'movimientos muestra puntos con signo y declara el alcance parcial',
    (tester) async {
      final repo = DemoLoyaltyP2Repository();
      await mount(
        tester,
        const LoyaltyCustomerScreen(
          customerKey: key,
          view: LoyaltyCustomerView.points,
        ),
        repo: repo,
      );
      expect(find.text('-10 puntos'), findsOneWidget);
      expect(find.text('+50 puntos'), findsOneWidget);
      expect(
        find.textContaining('Solo movimientos de puntos.'),
        findsOneWidget,
      );
      expect(repo.movementCalls, [11]);
      expect(repo.enrollmentCalls, everyElement(11));
    },
  );

  testWidgets(
    'cupones muestra estados reales de inscripción, sin deducir disponibilidad',
    (tester) async {
      final repo = DemoLoyaltyP2Repository();
      await mount(
        tester,
        const LoyaltyCustomerScreen(
          customerKey: key,
          view: LoyaltyCustomerView.coupons,
        ),
        repo: repo,
      );
      expect(find.text('Estado registrado: Usado'), findsOneWidget);
      expect(find.text('Estado registrado: Vencido'), findsOneWidget);
      expect(find.text('3 cupones emitidos'), findsOneWidget);
      expect(repo.couponCalls, [11]);
      expect(repo.enrollmentCalls, everyElement(11));
      expect(find.text('Premio disponible'), findsNothing);
    },
  );

  testWidgets(
    'clientes sin permiso de cupones no puede abrirlos directamente',
    (tester) async {
      final repo = DemoLoyaltyP2Repository();
      final session = LoyaltySessionNotifier(
        loyaltySession(roles: ['LOYALTI_CONFIG_VER', 'LOYALTI_CUSTOMERS_VER']),
      );
      await mount(
        tester,
        const LoyaltyCustomerScreen(
          customerKey: key,
          view: LoyaltyCustomerView.coupons,
        ),
        repo: repo,
        session: session,
      );
      expect(repo.couponCalls, isEmpty);
      expect(repo.enrollmentCalls, isEmpty);
      expect(find.text('María de prueba'), findsNothing);
    },
  );

  testWidgets('error de clientes permite reintentar sin perder la tarjeta', (
    tester,
  ) async {
    final repo = DemoLoyaltyP2Repository()
      ..customerFailure = Exception('Sin conexión');
    await mount(
      tester,
      const LoyaltyCustomersScreen(companyId: 1, card: p2Card),
      repo: repo,
    );
    expect(find.text('Sin conexión'), findsOneWidget);
    repo.customerFailure = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('María de prueba'), findsOneWidget);
    expect(repo.customerCalls.length, 2);
  });

  for (final view in LoyaltyCustomerView.values) {
    testWidgets('revocar permiso oculta datos en $view', (tester) async {
      final session = LoyaltySessionNotifier(loyaltySession(roles: p2Roles));
      await mount(
        tester,
        LoyaltyCustomerScreen(customerKey: key, view: view),
        session: session,
      );
      expect(find.text('María de prueba'), findsOneWidget);
      session.replace(loyaltySession(roles: []));
      await tester.pumpAndSettle();
      expect(find.text('María de prueba'), findsNothing);
      expect(find.text('Documento: 12345678'), findsNothing);
      expect(tester.takeException(), null);
    });
  }

  testWidgets('actualizar vuelve a leer el saldo del backend', (tester) async {
    final repo = DemoLoyaltyP2Repository();
    await mount(
      tester,
      const LoyaltyCustomerScreen(customerKey: key),
      repo: repo,
    );
    repo.enrollments[0] = const LoyaltyCustomer(
      id: 11,
      cardId: 1,
      name: 'María de prueba',
      cardName: 'Recargas de prueba',
      stamps: 14,
      availablePoints: 73,
      active: true,
    );
    await tester.tap(find.byTooltip('Actualizar'));
    await tester.pumpAndSettle();
    expect(find.text('73'), findsOneWidget);
    expect(find.text('40'), findsNothing);
    expect(repo.enrollmentCalls, [11, 11]);
  });

  for (final view in LoyaltyCustomerView.values) {
    testWidgets('pantalla pequeña y texto ampliado: $view', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = DemoLoyaltyP2Repository(
        enrollments: [
          LoyaltyCustomer(
            id: 11,
            cardId: 1,
            name:
                'Cliente de prueba con un nombre muy largo para comprobar el ajuste de texto',
            cardName: 'Recargas de prueba con nombre de programa extenso',
            stamps: 14,
            active: true,
          ),
        ],
      );
      await mount(
        tester,
        LoyaltyCustomerScreen(customerKey: key, view: view),
        repo: repo,
        scale: 2,
      );
      expect(tester.takeException(), null);
    });
  }
  testWidgets('listado de clientes en pantalla pequeña con texto ampliado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(
      tester,
      const LoyaltyCustomersScreen(companyId: 1, card: p2Card),
      scale: 2,
    );
    expect(tester.takeException(), null);
  });
}
