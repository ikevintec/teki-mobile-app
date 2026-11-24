import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_main_screen.dart';
import 'package:teki_app/src/presentation/screens/dashboard/navigation/dashboard_bottom_bar.dart';
import 'package:teki_app/src/presentation/screens/dashboard/navigation/dashboard_menu.dart';
import 'package:teki_app/src/presentation/screens/dashboard/navigation/dashboard_navigation.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import '../support/dashboard_fixture.dart';
import '../support/loyalty_fixture.dart';

Future<void> pumpDashboard(WidgetTester tester) async {
  // El orbe del asistente mantiene una animación continua: esperar cuadros
  // acotados, sin pedir que toda la app deje de animarse.
  for (var frame = 0; frame < 12; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late DashboardAdapter adapter;
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    dotenv.loadFromString(envString: 'API_URL=https://example.com/api');
    await initializeDateFormatting('es');
  });
  setUp(() {
    adapter = DashboardAdapter();
    ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'))
      ..httpClientAdapter = adapter;
  });
  tearDown(() {
    ApiClient.dio.close(force: true);
    Get.reset();
  });

  for (final roles in [
    <String>[],
    ['VENTAS_CREAR'],
    ['CLIENTES_VER'],
    ['SUPER_USUARIO'],
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('menú completo/restringido $roles texto $scale en 320px', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final session = dashboardSession(roles: roles);
        DashboardAction? tapped;
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: DashboardMenu(
                  session: session,
                  onAction: (action) => tapped = action,
                ),
              ),
              bottomNavigationBar: DashboardBottomBar(
                destinations: dashboardDestinations(session),
                selected: DashboardDestination.home,
                onSelected: (_) {},
              ),
            ),
          ),
        );
        await pumpDashboard(tester);
        expect(find.text('Más opciones'), findsNothing);
        expect(tester.takeException(), isNull);
        final firstAction = dashboardGroups(session).first.actions.first;
        await tester.ensureVisible(
          find.byKey(ValueKey('menu-${firstAction.name}')),
        );
        await tester.tap(find.byKey(ValueKey('menu-${firstAction.name}')));
        expect(tapped, firstAction);
        final scrollable = find.byType(Scrollable).first;
        await tester.drag(scrollable, const Offset(0, -5000));
        await pumpDashboard(tester);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'Clientes abre dentro del dashboard y revocar permiso vuelve a Inicio',
    (tester) async {
      final session = dashboardSession(roles: ['CLIENTES_VER']);
      final notifier = LoyaltySessionNotifier(session);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sesionProvider.overrideWith((_) => notifier)],
          child: const GetMaterialApp(home: DashboardMainScreen()),
        ),
      );
      await pumpDashboard(tester);
      expect(
        adapter.requests,
        isEmpty,
      ); // No consulta ventas/caja sin sus permisos.
      expect(find.byKey(const ValueKey('tab-customers')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tab-customers')));
      await pumpDashboard(tester);
      expect(adapter.requests.where((r) => r.path == '/customers').length, 1);
      expect(find.text('Cliente de demostración'), findsOneWidget);
      expect(find.text('Crear cliente'), findsNothing);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.byType(DashboardBottomBar), findsOneWidget);
      notifier.replace(dashboardSession(roles: []));
      await pumpDashboard(tester);
      expect(find.byKey(const ValueKey('tab-customers')), findsNothing);
      expect(find.text('Cliente de demostración'), findsNothing);
      expect(find.text('Administración'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'perfil solo ventas no consulta caja y solo caja no consulta ventas',
    (tester) async {
      for (final role in ['VENTAS_VER', 'CAJA_VER']) {
        final session = dashboardSession(roles: [role]);
        adapter.requests.clear();
        await tester.pumpWidget(
          ProviderScope(
            key: ValueKey(role),
            overrides: [
              sesionProvider.overrideWith(
                (_) => LoyaltySessionNotifier(session),
              ),
            ],
            child: const GetMaterialApp(home: DashboardMainScreen()),
          ),
        );
        await pumpDashboard(tester);
        expect(
          adapter.requests.where((r) => r.path == '/tickets').isNotEmpty,
          role == 'VENTAS_VER',
        );
        expect(
          adapter.requests.where((r) => r.path == '/cash-register').isNotEmpty,
          role == 'CAJA_VER',
        );
        expect(
          find.text('Ver detalle'),
          findsNothing,
        ); // Requiere REPORTE_VENTAS.
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'dashboard y Clientes completos con texto 200% en teléfono pequeño',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sesionProvider.overrideWith(
              (_) => LoyaltySessionNotifier(dashboardSession()),
            ),
          ],
          child: GetMaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: const DashboardMainScreen(),
          ),
        ),
      );
      await pumpDashboard(tester);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('tab-customers')));
      await pumpDashboard(tester);
      expect(find.text('Cliente de demostración'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
