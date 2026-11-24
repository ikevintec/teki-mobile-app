import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/presentation/screens/dashboard/navigation/dashboard_navigation.dart';
import 'package:teki_app/src/presentation/screens/restaurant/cobrador/cobrador_screen.dart';
import 'package:teki_app/src/presentation/screens/restaurant/restaurant_mesas_screen.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/restaurant/cobrador_provider.dart';
import 'package:teki_app/src/providers/restaurant/restaurant_provider.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import '../support/dashboard_fixture.dart';
import '../support/loyalty_fixture.dart';
import '../support/restaurant_fixture.dart';

void main() {
  setUpAll(() async {
    final font = FontLoader('Roboto')..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    await font.load();
  });
  setUp(() {
    Get.testMode = true;
    dotenv.loadFromString(
      envString:
          'API_URL=https://example.invalid/api\nWS_URL=http://127.0.0.1:9\nWS_PATH=/qa',
    );
    ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
      ..httpClientAdapter = DashboardAdapter();
  });

  for (final role in [
    '',
    'RESTAURANTE_COMANDAS_VER',
    'RESTAURANTE_COBRADOR_VER',
    'SUPER_USUARIO',
  ]) {
    testWidgets('menú y pantalla Cobrador coinciden para rol $role', (
      tester,
    ) async {
      final session = dashboardSession(roles: [if (role.isNotEmpty) role]);
      final allowed =
          role == 'RESTAURANTE_COBRADOR_VER' || role == 'SUPER_USUARIO';
      final actions = dashboardGroups(session).expand((group) => group.actions);
      expect(actions.contains(DashboardAction.collector), allowed);
      final repo = RestaurantFixture();
      await tester.pumpWidget(
        _app(session, repo, const CobradorScreen(pvId: 1)),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('No tienes permisos para ver el cobrador'),
        allowed ? findsNothing : findsOneWidget,
      );
      expect(repo.checkCalls, allowed ? 1 : 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'detalle distingue cancelados, rechazados y eliminados sin alterar total',
    (tester) async {
      final repo = RestaurantFixture();
      await tester.pumpWidget(
        _app(dashboardSession(), repo, const CobradorScreen(pvId: 1)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('50.00').first);
      await tester.pumpAndSettle();
      expect(find.text('Cancelado · No se cobra'), findsNWidgets(3));
      for (final name in ['Cancelado QA', 'Rechazado QA', 'Eliminado QA']) {
        expect(
          tester.widget<Text>(find.text(name)).style?.decoration,
          TextDecoration.lineThrough,
        );
      }
      expect(
        tester.widget<Text>(find.text('Lomo QA')).style?.decoration,
        isNull,
      );
      expect(find.text('S/ 50.00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('mesa llamando sin mozo cabe en grilla real de iPhone SE', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(
        dashboardSession(roles: ['RESTAURANTE_MESAS_VER']),
        RestaurantFixture(),
        const RestaurantMesasScreen(),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('LLAMANDO'), findsOneWidget);
    expect(find.text('Mesa 3'), findsOneWidget);
    expect(find.text('Salón principal'), findsWidgets);
    expect(find.textContaining('items'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}

Widget _app(SesionState session, RestaurantFixture repo, Widget screen) =>
    ProviderScope(
      overrides: [
        sesionProvider.overrideWith((_) => LoyaltySessionNotifier(session)),
        cobradorProvider.overrideWith(
          (_) => CobradorNotifier(repository: repo),
        ),
        restaurantProvider.overrideWith(
          (_) => RestaurantNotifier(repository: repo),
        ),
      ],
      child: GetMaterialApp(theme: ThemeData(fontFamily: 'Roboto'), home: screen),
    );
