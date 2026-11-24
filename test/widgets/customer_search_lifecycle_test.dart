import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/screens/customer/customer_main_screen.dart';
import 'package:teki_app/src/presentation/screens/customer/widgets/customer_filters_modal.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/customers/customers.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import '../support/dashboard_fixture.dart';
import '../support/loyalty_fixture.dart';

void main() {
  late DashboardAdapter adapter;
  late LoyaltySessionNotifier session;
  late ProviderContainer container;

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    dotenv.loadFromString(envString: 'API_URL=https://example.invalid/api');
    adapter = DashboardAdapter();
    ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
      ..httpClientAdapter = adapter;
    session = LoyaltySessionNotifier(dashboardSession());
    container = ProviderContainer(
      overrides: [sesionProvider.overrideWith((_) => session)],
    );
  });
  tearDown(() {
    container.dispose();
    ApiClient.dio.close(force: true);
  });

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CustomerMainScreen(embedded: true)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Norte');
    await tester.pump(const Duration(milliseconds: 401));
    await tester.pumpAndSettle();
    expect(container.read(customersProvider).filtro, 'Norte');
  }

  void expectNoDeferredSur() {
    expect(
      adapter.requests.where(
        (request) =>
            request.path == '/customers' &&
            request.queryParameters['filtro'] == 'Sur',
      ),
      isEmpty,
    );
  }

  testWidgets('limpiar clientes cancela el filtro todavía en debounce', (
    tester,
  ) async {
    await mount(tester);
    await tester.enterText(find.byType(TextField), 'Sur');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byIcon(Icons.cleaning_services_outlined));
    await tester.pump();
    expect(container.read(customersProvider).filtro, isNull);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();
    expect(container.read(customersProvider).filtro, anyOf(isNull, isEmpty));
    expectNoDeferredSur();
  });

  testWidgets(
    'aplicar filtro del modal cancela la búsqueda anterior pendiente',
    (tester) async {
      await mount(tester);
      await tester.enterText(find.byType(TextField), 'Sur');
      await tester.tap(find.byIcon(Icons.filter_alt_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final modalSearch = find
          .descendant(
            of: find.byType(CustomerFiltersModal),
            matching: find.byType(TextField),
          )
          .first;
      await tester.enterText(modalSearch, 'Centro');
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(container.read(customersProvider).filtro, 'Centro');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Centro',
      );
      expectNoDeferredSur();
    },
  );

  testWidgets(
    'renovar sesión limpia el buscador y cancela la búsqueda pendiente',
    (tester) async {
      await mount(tester);
      await tester.enterText(find.byType(TextField), 'Sur');
      session.replace(dashboardSession());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(container.read(customersProvider).filtro, anyOf(isNull, isEmpty));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
      expectNoDeferredSur();
    },
  );
}
