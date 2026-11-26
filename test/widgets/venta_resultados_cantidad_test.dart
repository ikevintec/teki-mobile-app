import 'package:teki_app/src/data/models/teki_model/batch_product.dart';
import 'package:teki_app/src/data/models/teki_model/batch_product_sale.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail.dart';
import 'package:teki_app/src/presentation/screens/sale/products/products_sale_screen.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import '../support/loyalty_fixture.dart';
import '../support/pedidos_fixture.dart';
import '../support/pedidos_opciones_fixture.dart';

const nombre = 'Arroz extra 1 kg';
Finder accion(String texto) => find.byTooltip('$texto $nombre');
Finder get cantidad => find.byTooltip('Cambiar cantidad de $nombre');
Finder get entrada =>
    find.widgetWithText(TextFormField, 'Cantidad mayor a cero');

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
          home: const ProductsSaleScreen(),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
  await t.enterText(find.widgetWithText(TextField, 'Buscar producto'), 'Arroz');
  await t.pumpAndSettle();
  return c;
}

void abierta(WidgetTester t) {
  expect(find.text('Listo'), findsOneWidget);
  expect(find.text(nombre).last, findsOneWidget);
  expect(
    t
        .widget<TextField>(find.widgetWithText(TextField, 'Buscar producto'))
        .controller!
        .text,
    'Arroz',
  );
}

void main() {
  setUpAll(() async {
    final fuente = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    await fuente.load();
  });
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(1024, 768),
  ]) {
    testWidgets(
      'agregar, editar, cancelar, disminuir y quitar sin Listo $size',
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
        await t.tap(accion('Agregar'));
        await t.pumpAndSettle();
        abierta(t);
        expect(c.read(productSaleProvider).productsSales.single.cantidad, 2);
        await t.tap(cantidad);
        await t.pumpAndSettle();
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
        expect(
          c.read(ticketProvider).ticket.totalVenta,
          closeTo(70.125, .00001),
        );
        await t.tap(cantidad);
        await t.pumpAndSettle();
        await t.enterText(entrada, '99');
        await t.tap(find.text('Cancelar'));
        await t.pumpAndSettle();
        abierta(t);
        expect(
          c.read(productSaleProvider).productsSales.single.cantidad,
          12.75,
        );
        await t.tap(accion('Disminuir'));
        await t.pumpAndSettle();
        abierta(t);
        expect(
          c.read(productSaleProvider).productsSales.single.cantidad,
          11.75,
        );
        await t.tap(accion('Quitar'));
        await t.pumpAndSettle();
        abierta(t);
        expect(c.read(productSaleProvider).productsSales, isEmpty);
        await t.tap(accion('Agregar'));
        await t.pumpAndSettle();
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
  testWidgets(
    'varias líneas elige una; quitar conserva comanda y recalcula regalos',
    (t) async {
      final c = await abrir(t);
      await t.tap(accion('Agregar'));
      await t.pumpAndSettle();
      final notifier = c.read(productSaleProvider.notifier);
      final original = c.read(productSaleProvider).productsSales.single;
      notifier.setProductsSaleEntity([
        original.copyWith(
          uuid: 'locked',
          cantidad: 4,
          comandaDetalle: CommandDetail(id: 9),
        ),
        original.copyWith(uuid: 'a', cantidad: 2, precioManual: true),
        original.copyWith(uuid: 'b', cantidad: 3, precioManual: true),
        original.copyWith(uuid: 'gift', cantidad: 1, esBonificacion: true),
      ]);
      await t.pumpAndSettle();
      await t.tap(cantidad);
      await t.pumpAndSettle();
      expect(find.textContaining('Comanda (no editable)'), findsOneWidget);
      await t.tap(find.textContaining('Línea 3:'));
      await t.pumpAndSettle();
      await t.enterText(entrada, '1.5');
      await t.tap(find.text('Aceptar'));
      await t.pumpAndSettle();
      abierta(t);
      expect(
        c
            .read(productSaleProvider)
            .productsSales
            .firstWhere((l) => l.uuid == 'a')
            .cantidad,
        2,
      );
      expect(
        c
            .read(productSaleProvider)
            .productsSales
            .firstWhere((l) => l.uuid == 'b')
            .cantidad,
        1.5,
      );
      await t.tap(accion('Quitar'));
      await t.pumpAndSettle();
      abierta(t);
      expect(c.read(productSaleProvider).productsSales.map((l) => l.uuid), [
        'locked',
      ]);
      final boton = find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip == 'Quitar $nombre',
      );
      expect(t.widget<IconButton>(boton).onPressed, isNull);
      await t.tap(accion('Quitar'), warnIfMissed: false);
      await t.pumpAndSettle();
      expect(c.read(productSaleProvider).productsSales.map((l) => l.uuid), [
        'locked',
      ]);
      await t.pump(const Duration(seconds: 2));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'editar y disminuir conserva la serie elegida y ajusta su cantidad',
    (t) async {
      final c = await abrir(t);
      await t.tap(accion('Agregar'));
      await t.pumpAndSettle();
      final original = c.read(productSaleProvider).productsSales.single;
      final series = [
        for (final id in [1, 2, 3])
          BatchProduct(id: id, tipoLote: 'SERIE', serie: 'S$id', cantidad: 1),
      ];
      c.read(productSaleProvider.notifier).setProductsSaleEntity([
        original.copyWith(
          uuid: 'serial',
          producto: original.producto!.copyWith(
            tipoLote: 'SERIE',
            inventarios: [
              Inventory(puntoVenta: Office(id: 1), stock: 3, lotes: series),
            ],
          ),
          lotes: [BatchProductSale(lote: series.last, cantidad: 1)],
        ),
      ]);
      await t.pumpAndSettle();
      await t.tap(cantidad);
      await t.pumpAndSettle();
      await t.enterText(entrada, '2');
      await t.tap(find.text('Aceptar'));
      await t.pumpAndSettle();
      abierta(t);
      expect(
        c
            .read(productSaleProvider)
            .productsSales
            .single
            .lotes!
            .map((l) => l.lote!.id),
        [3, 1],
      );
      await t.tap(accion('Disminuir'));
      await t.pumpAndSettle();
      expect(
        c
            .read(productSaleProvider)
            .productsSales
            .single
            .lotes!
            .map((l) => l.lote!.id),
        [3],
      );
      await t.pump(const Duration(seconds: 2));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
  );
}
