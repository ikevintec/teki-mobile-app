import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/customer.dart';
import 'package:teki_app/src/presentation/screens/sale/client/client_sale_screen.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_provider.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import '../support/pedidos_fixture.dart';
import '../support/loyalty_fixture.dart';
import '../support/dashboard_fixture.dart';

void main() {
  testWidgets(
    'tocar nombre selecciona todo y escribir no se pierde al reconstruir',
    (tester) async {
      dotenv.loadFromString(envString: 'API_URL=https://example.invalid/api');
      ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
        ..httpClientAdapter = DashboardAdapter();
      final session = pedidosSession();
      final generic = Customer(
        id: 10,
        razonSocial: 'Clientes varios',
        tipoDocumento: '0',
        numeroDocumento: '-',
        porDefecto: true,
      );
      session.config!.clientePorDefectoData = generic;
      final container = ProviderContainer(
        overrides: [
          sesionProvider.overrideWith((_) => LoyaltySessionNotifier(session)),
        ],
      );
      addTearDown(container.dispose);
      container.read(customerSaleProvider.notifier).setCustomerEntity(generic);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ClientSaleScreen()),
        ),
      );
      await tester.pumpAndSettle();
      final input = find.widgetWithText(TextFormField, 'Nombre');
      await tester.tap(input);
      await tester.pump();
      final field = tester.widget<TextFormField>(input);
      expect(
        field.controller!.selection,
        const TextSelection(baseOffset: 0, extentOffset: 15),
      );
      await tester.enterText(input, 'Ana de prueba');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(input).controller!.text,
        'Ana de prueba',
      );
      await tester.enterText(input, '');
      await tester.pumpAndSettle();
      expect(tester.widget<TextFormField>(input).controller!.text, '');
      await tester.tap(find.byType(ElevatedButton).last);
      await tester.pumpAndSettle();
      expect(find.text('Ingrese el nombre del cliente'), findsOneWidget);
      expect(
        container.read(customerSaleProvider).customer.razonSocial,
        'Clientes varios',
      );
      await tester.enterText(input, 'Ana final');
      await tester.tap(find.byType(ElevatedButton).last);
      expect(
        container.read(customerSaleProvider).customer.razonSocial,
        'Ana final',
      );
      container.read(ticketProvider.notifier).setTicketsData();
      expect(
        container.read(ticketProvider).ticket.denominacionReceptor,
        'Ana final',
      );
      expect(container.read(ticketProvider).ticket.cliente!.id, 10);
      expect(generic.razonSocial, 'Clientes varios');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );
  testWidgets(
    'seleccionar sugerencia reemplaza cliente sin alterar el genérico',
    (tester) async {
      dotenv.loadFromString(envString: 'API_URL=https://example.invalid/api');
      ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
        ..httpClientAdapter = DashboardAdapter();
      final generic = Customer(
        id: 10,
        razonSocial: 'Clientes varios',
        tipoDocumento: '0',
        numeroDocumento: '-',
        porDefecto: true,
      );
      final session = pedidosSession();
      session.config!.clientePorDefectoData = generic;
      final container = ProviderContainer(
        overrides: [
          sesionProvider.overrideWith((_) => LoyaltySessionNotifier(session)),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ClientSaleScreen()),
        ),
      );
      await tester.pumpAndSettle();
      final input = find.widgetWithText(TextFormField, 'Nombre');
      await tester.enterText(input, 'Cliente');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ListTile, 'Cliente de demostración'),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(input).controller!.text,
        'Cliente de demostración',
      );
      await tester.tap(find.byType(ElevatedButton).last);
      expect(container.read(customerSaleProvider).customer.id, 1);
      expect(
        container.read(customerSaleProvider).customer.razonSocial,
        'Cliente de demostración',
      );
      expect(generic.razonSocial, 'Clientes varios');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );
}
