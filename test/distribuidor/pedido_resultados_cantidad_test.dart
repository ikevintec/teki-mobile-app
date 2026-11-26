import 'package:teki_app/src/presentation/screens/pedidos/pedido_form.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:teki_app/src/presentation/screens/pedidos/pedidos_screen.dart';
import 'package:teki_app/src/presentation/widgets/product_search_result.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import '../support/loyalty_fixture.dart';
import '../support/pedidos_fixture.dart';
import '../support/pedidos_opciones_fixture.dart';

const nombre = 'Arroz extra 1 kg';
Finder accion(String texto) => find.byTooltip('$texto $nombre');
Finder get cantidad => find.byTooltip('Cambiar cantidad de $nombre');
Finder get entrada =>
    find.widgetWithText(TextFormField, 'Cantidad mayor a cero');
Finder get consulta => find.widgetWithText(TextField, 'Buscar producto');

Future<ProviderContainer> abrir(WidgetTester t) async {
  Get.reset();
  SharedPreferences.setMockInitialValues({});
  ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
    ..httpClientAdapter = (PedidosOpcionesAdapter()..comercial = false);
  final c = ProviderContainer(
    overrides: [
      sesionProvider.overrideWith(
        (_) => LoyaltySessionNotifier(pedidosSession()),
      ),
    ],
  );
  addTearDown(c.dispose);
  await t.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: ToastificationWrapper(
        child: GetMaterialApp(
          theme: ThemeData(fontFamily: 'Roboto'),
          home: const PedidosScreen(),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
  await t.tap(find.text('Nuevo pedido'));
  await t.pumpAndSettle();
  await t.scrollUntilVisible(
    find.text('Agregar productos'),
    150,
    scrollable: find.byType(Scrollable).first,
  );
  await t.pumpAndSettle();
  await t.tap(find.text('Agregar productos'));
  await t.pumpAndSettle();
  await t.enterText(consulta, 'Arroz');
  await t.pumpAndSettle();
  return ProviderScope.containerOf(t.element(find.byType(PedidoForm)));
}

void abierta(WidgetTester t) {
  expect(find.byType(ProductSearchResult), findsOneWidget);
  expect(find.text('Listo'), findsOneWidget);
  expect(t.widget<TextField>(consulta).controller!.text, 'Arroz');
}

void main() {
  setUpAll(() async {
    final font = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    await font.load();
  });
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(1024, 768),
  ]) {
    testWidgets(
      'pedido: controles y resultado compartidos mantienen consulta $size',
      (t) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final c = await abrir(t);
        await t.tap(accion('Agregar'));
        await t.pumpAndSettle();
        abierta(t);
        expect(c.read(productSaleProvider).productsSales.single.cantidad, 1);
        final principal = ProviderScope.containerOf(
          t.element(find.byType(PedidosScreen, skipOffstage: false)),
        );
        expect(principal.read(productSaleProvider).productsSales, isEmpty);
        await t.tap(accion('Agregar'));
        await t.pumpAndSettle();
        expect(c.read(productSaleProvider).productsSales.single.cantidad, 2);
        await t.tap(accion('Disminuir'));
        await t.pumpAndSettle();
        abierta(t);
        expect(c.read(productSaleProvider).productsSales.single.cantidad, 1);
        await t.tap(cantidad);
        // La operación espera al modal y mantiene indicador de progreso detrás.
        await t.pump();
        await t.pump(const Duration(milliseconds: 500));
        await t.enterText(entrada, '12,75');
        await t.pump(const Duration(seconds: 2));
        expect(
          t
              .widget<EditableText>(
                find.descendant(
                  of: entrada,
                  matching: find.byType(EditableText),
                ),
              )
              .focusNode
              .hasFocus,
          isTrue,
        );
        await t.tap(find.text('Aceptar'));
        await t.pumpAndSettle();
        abierta(t);
        expect(
          c.read(productSaleProvider).productsSales.single.cantidad,
          12.75,
        );
        await t.tap(cantidad);
        // La operación espera al modal y mantiene indicador de progreso detrás.
        await t.pump();
        await t.pump(const Duration(milliseconds: 500));
        await t.enterText(entrada, '99');
        await t.tap(find.text('Cancelar'));
        await t.pumpAndSettle();
        abierta(t);
        expect(
          c.read(productSaleProvider).productsSales.single.cantidad,
          12.75,
        );
        await t.tap(accion('Quitar'));
        await t.pumpAndSettle();
        abierta(t);
        expect(c.read(productSaleProvider).productsSales, isEmpty);
        await t.tap(accion('Agregar'));
        await t.pumpAndSettle();
        abierta(t);
        expect(c.read(productSaleProvider).productsSales.single.cantidad, 1);
        await t.tap(accion('Disminuir'));
        await t.pumpAndSettle();
        abierta(t);
        expect(c.read(productSaleProvider).productsSales, isEmpty);
        await t.pump(const Duration(seconds: 2));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      },
    );
  }
}
