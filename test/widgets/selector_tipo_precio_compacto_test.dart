import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:teki_app/src/presentation/screens/sale/products/products_sale_screen.dart';
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
  for (final size in [const Size(390, 844), const Size(1024, 768)]) {
    testWidgets('selector compacto conserva líneas existentes $size', (
      t,
    ) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      Get.reset();
      SharedPreferences.setMockInitialValues({});
      final api = PedidosOpcionesAdapter()..comercial = true;
      ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
        ..httpClientAdapter = api;
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
      expect(container.read(productSaleProvider).productsSales, hasLength(1));
      // La búsqueda queda abierta para seguir sumando; se cierra con "Listo".
      await t.tap(find.text('Listo'));
      await t.pumpAndSettle();

      await t.tap(find.byTooltip('Agregar producto'));
      await t.pumpAndSettle();
      expect(find.text('Crear Producto'), findsOneWidget);
      expect(find.text('Producto Libre'), findsOneWidget);
      await t.tapAt(const Offset(10, 100));
      await t.pumpAndSettle();
      final selector = find.byTooltip('Tipo de precio para nuevos productos');
      expect(t.getSize(selector).width, lessThanOrEqualTo(240));
      expect(t.getSize(selector).height, greaterThanOrEqualTo(44));
      final anterior = container.read(productSaleProvider).productsSales.single;
      await t.tap(selector);
      await t.pumpAndSettle();
      expect(
        t
            .widgetList<CheckedPopupMenuItem<int>>(
              find.byType(CheckedPopupMenuItem<int>),
            )
            .where((i) => i.checked),
        hasLength(1),
      );
      await t.tap(find.widgetWithText(CheckedPopupMenuItem<int>, 'Mayorista'));
      await t.pumpAndSettle();
      expect(container.read(ticketProvider).ticket.tipoPrecioCabeceraId, 2);
      final posterior = container
          .read(productSaleProvider)
          .productsSales
          .single;
      expect(posterior.precioVentaUnitario, anterior.precioVentaUnitario);
      expect(posterior.toJson(), anterior.toJson());
      await t.pump(const Duration(seconds: 2));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  }
}
