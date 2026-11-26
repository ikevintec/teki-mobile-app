import 'package:teki_app/src/data/models/teki_model/config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:teki_app/src/presentation/screens/sale/products/products_sale_screen.dart';
import 'package:teki_app/src/presentation/screens/sale/products/widgets/product_item_card.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import '../support/loyalty_fixture.dart';
import '../support/pedidos_fixture.dart';
import '../support/pedidos_opciones_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Mismas métricas que la app; Ahem ensancha falsamente las etiquetas.
    final fuente = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    await fuente.load();
  });
  testWidgets(
    'venta con búsqueda local y caché vacía abre sin modificar providers durante build',
    (t) async {
      Get.reset();
      SharedPreferences.setMockInitialValues({});
      ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
        ..httpClientAdapter = PedidosOpcionesAdapter();
      final session = pedidosSession();
      final container = ProviderContainer(
        overrides: [
          sesionProvider.overrideWith(
            (_) => LoyaltySessionNotifier(
              session.copyWith(
                config: ConfigCompany.fromJson({
                  ...session.config!.toJson(),
                  'busquedaProductosLocalmente': true,
                }),
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: ToastificationWrapper(
            child: GetMaterialApp(
              theme: ThemeData(fontFamily: 'Roboto'),
              home: const ProductsSaleScreen(),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Continuar'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('continuar sin precio dice qué producto lo necesita', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
      ..httpClientAdapter = PedidosOpcionesAdapter();
    final container = ProviderContainer(
      overrides: [
        sesionProvider.overrideWith(
          (_) => LoyaltySessionNotifier(pedidosSession()),
        ),
      ],
    );
    addTearDown(container.dispose);
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ToastificationWrapper(
          child: GetMaterialApp(
            theme: ThemeData(fontFamily: 'Roboto'),
            home: const ProductsSaleScreen(),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('Continuar'));
    await t.pumpAndSettle();
    expect(
      find.text('Agrega al menos un producto para continuar.'),
      findsOneWidget,
    );

    await t.enterText(
      find.widgetWithText(TextField, 'Buscar producto'),
      'Arroz',
    );
    await t.pumpAndSettle();
    await t.tap(find.text('Arroz extra 1 kg').last);
    await t.pumpAndSettle();
    await t.tap(find.text('Listo'));
    await t.pumpAndSettle();
    container.read(productSaleProvider.notifier).setPrecioProductSale(0, 0);
    await t.pumpAndSettle();
    await t.tap(find.text('Continuar'));
    await t.pumpAndSettle();
    expect(find.text('Falta el precio de «Arroz extra 1 kg».'), findsOneWidget);
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
  });

  for (final size in [const Size(390, 844), const Size(1024, 768)]) {
    for (final comercial in [false, true]) {
      for (final incIgv in [true, false]) {
        testWidgets(
          'venta de pantalla: cantidad confirma precio elegido comercial=$comercial incIgv=$incIgv tamaño=$size',
          (t) async {
            t.view.physicalSize = size;
            t.view.devicePixelRatio = 1;
            addTearDown(t.view.resetPhysicalSize);
            addTearDown(t.view.resetDevicePixelRatio);
            Get.reset();
            SharedPreferences.setMockInitialValues({});
            final api = PedidosOpcionesAdapter()..comercial = comercial;
            ApiClient.dio = Dio(
              BaseOptions(baseUrl: 'https://example.invalid/api'),
            )..httpClientAdapter = api;
            final container = ProviderContainer(
              overrides: [
                sesionProvider.overrideWith(
                  (_) => LoyaltySessionNotifier(pedidosSession()),
                ),
              ],
            );
            addTearDown(container.dispose);
            await t.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: ToastificationWrapper(
                  child: GetMaterialApp(
                    theme: ThemeData(fontFamily: 'Roboto'),
                    home: const ProductsSaleScreen(),
                  ),
                ),
              ),
            );
            await t.pumpAndSettle();
            await t.enterText(
              find.widgetWithText(TextField, 'Buscar producto'),
              'Arroz',
            );
            await t.pumpAndSettle();
            await t.tap(find.text('Arroz extra 1 kg').last);
            await t.pumpAndSettle();
            expect(
              container.read(productSaleProvider).productsSales,
              hasLength(1),
            );
            // La búsqueda queda abierta para seguir sumando; se cierra con "Listo".
            await t.tap(find.text('Listo'));
            await t.pumpAndSettle();
            if (!incIgv) {
              await t.tap(find.text('Si'));
              await t.pumpAndSettle();
            }
            if (comercial) {
              await t.tap(find.widgetWithText(TextButton, 'Minorista'));
              await t.pumpAndSettle();
              await t.tap(find.text('Mayorista').last);
              await t.pumpAndSettle();
              await t.tap(find.widgetWithText(TextButton, 'Mayorista'));
              await t.pumpAndSettle();
              await t.tap(find.text('Ingresar precio manual'));
              await t.pumpAndSettle();
              await t.enterText(
                find.widgetWithText(TextFormField, 'Precio unitario'),
                incIgv ? '7.25' : '${7.25 / 1.18}',
              );
              await t.tap(find.text('Aplicar'));
              await t.pumpAndSettle();
              expect(
                container
                    .read(productSaleProvider)
                    .productsSales
                    .single
                    .precioVentaUnitario,
                closeTo(7.25, .00001),
              );
            }
            final cantidad = find.descendant(
              of: find.byType(QuantityControl),
              matching: find.byType(TextField),
            );
            await t.enterText(cantidad, '10');
            await t.testTextInput.receiveAction(TextInputAction.done);
            await t.pumpAndSettle();
            expect(
              container
                  .read(productSaleProvider)
                  .productsSales
                  .single
                  .precioVentaUnitario,
              closeTo(comercial ? 7.25 : 5.5, .00001),
            );
            expect(
              container.read(ticketProvider).ticket.totalVenta,
              closeTo(comercial ? 72.5 : 55, .00001),
            );
            await t.pump(const Duration(seconds: 2));
            await t.pumpAndSettle();
            expect(t.takeException(), isNull);
          },
        );
      }
    }
  }
}
