import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/presentation/screens/orders_restaurant/widgets/direct_order_checkout_screen.dart';
import 'package:teki_app/src/providers/restaurant/direct_checkout/direct_checkout_service.dart';
import '../test/support/direct_checkout_fixture.dart' show CheckoutService;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:teki_app/src/data/models/teki_model/check.dart';
import 'package:teki_app/src/data/models/teki_model/customer.dart';
import 'package:teki_app/src/data/models/teki_model/order_restaurant.dart';
import 'package:teki_app/src/presentation/screens/sale/client/client_sale_screen.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_provider.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import '../test/widgets/direct_order_checkout_screen_test.dart' as checkout;
import '../test/providers/sale_customer_preload_test.dart' show CustomerAdapter;
import '../test/support/loyalty_fixture.dart';
import '../test/support/pedidos_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;
  for (final initial in <String?>[null, 'Nombre previo del pedido']) {
    testWidgets('emisión directa restaurante: $initial', (tester) async {
      dotenv.loadFromString(envString: 'API_URL=https://example.invalid/api');
      final generic = Customer(
        id: 10,
        razonSocial: 'Clientes varios',
        tipoDocumento: '0',
        numeroDocumento: '-',
        porDefecto: true,
      );
      ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
        ..httpClientAdapter = NativeAdapter(generic);
      final service = CheckoutService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sesionProvider.overrideWith((_) => checkout.GenericSession()),
            directCheckoutServiceProvider.overrideWithValue(service),
          ],
          child: MaterialApp(
            home: DirectOrderCheckoutScreen(
              order: OrderRestaurant(
                denominacionReceptor: initial,
                comandas: [
                  Command(
                    items: [
                      CommandDetail(
                        producto: Product(id: 3, nombre: 'Producto QA'),
                        cantidad: 2.5,
                        precioVenta: 7.77,
                        grupoProductoOpciones: [],
                        preparacionProductoOpciones: [],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final input = find.widgetWithText(TextFormField, 'Nombre o documento');
      await tester.ensureVisible(input);
      await tester.tap(input);
      await tester.pumpAndSettle();
      final controller = tester.widget<TextFormField>(input).controller!;
      expect(controller.text, initial ?? 'Clientes varios');
      expect(
        controller.selection,
        TextSelection(baseOffset: 0, extentOffset: controller.text.length),
      );
      await binding.takeScreenshot(
        'nombre-restaurante-directo-${initial == null ? 'nuevo' : 'precarga'}',
      );
      await tester.enterText(input, 'Ana del restaurante');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Emitir comprobante'));
      await tester.tap(find.text('Emitir comprobante'));
      await tester.pumpAndSettle();
      final pedido = service.sent.single['pedido'] as Map;
      expect(pedido['denominacionReceptor'], 'Ana del restaurante');
      expect(pedido['cliente']['id'], 10);
      expect(pedido['cliente']['razonSocial'], 'Clientes varios');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }
  for (final flow in [
    'directa',
    'editar',
    'restaurante',
    'cotizacion-venta',
    'editar-cotizacion',
  ]) {
    testWidgets('nombre del comprobante: $flow', (tester) async {
      dotenv.loadFromString(envString: 'API_URL=https://example.invalid/api');
      final generic = Customer(
        id: 10,
        razonSocial: 'Clientes varios',
        tipoDocumento: '0',
        numeroDocumento: '-',
        porDefecto: true,
      );
      ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
        ..httpClientAdapter = NativeAdapter(generic);
      final session = pedidosSession();
      session.config!.clientePorDefectoData = generic;
      session.config!.configuracionDistribuidor = {};
      final container = ProviderContainer(
        overrides: [
          sesionProvider.overrideWith((_) => LoyaltySessionNotifier(session)),
        ],
      );
      if (flow == 'editar') {
        await container.read(productSaleProvider.notifier).loadInitialData(7);
      } else if (flow == 'restaurante') {
        await container
            .read(productSaleProvider.notifier)
            .initFromCheck(
              Check(
                id: 1,
                cliente: generic,
                pedido: OrderRestaurant(
                  cliente: generic,
                  denominacionReceptor: 'Ana del pedido',
                ),
              ),
            );
      } else if (flow == 'cotizacion-venta' || flow == 'editar-cotizacion') {
        await container
            .read(productSaleProvider.notifier)
            .loadInitialData(
              null,
              quotationId: flow == 'editar-cotizacion' ? 8 : null,
              quotationIdForSale: flow == 'cotizacion-venta' ? 8 : null,
            );
      }
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ClientSaleScreen()),
        ),
      );
      await tester.pumpAndSettle();
      final input = find.widgetWithText(TextFormField, 'Nombre');
      final initial = flow == 'directa'
          ? 'Clientes varios'
          : flow == 'restaurante'
          ? 'Ana del pedido'
          : 'Ana del comprobante';
      expect(tester.widget<TextFormField>(input).controller!.text, initial);
      await tester.tap(input);
      await tester.pumpAndSettle();
      final controller = tester.widget<TextFormField>(input).controller!;
      expect(
        controller.selection,
        TextSelection(baseOffset: 0, extentOffset: initial.length),
      );
      await binding.takeScreenshot('nombre-$flow-seleccion');
      await tester.enterText(input, 'Nombre de prueba $flow');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton).last);
      expect(
        container.read(customerSaleProvider).customer.razonSocial,
        'Nombre de prueba $flow',
      );
      container.read(ticketProvider.notifier).setTicketsData();
      expect(
        container.read(ticketProvider).ticket.toJson()['denominacionReceptor'],
        'Nombre de prueba $flow',
      );
      expect(generic.razonSocial, 'Clientes varios');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      container.dispose();
      ApiClient.dio.close(force: true);
    });
  }
}

class NativeAdapter extends CustomerAdapter {
  NativeAdapter(super.generic);
  @override
  Future<ResponseBody> fetch(options, stream, cancel) async {
    if (options.path == '/customers') {
      return ResponseBody.fromString(
        '[]',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return super.fetch(options, stream, cancel);
  }
}
