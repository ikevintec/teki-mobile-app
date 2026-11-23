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
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/presentation/screens/sale/products/widgets/modal_product_view.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
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
  for (final comercial in [false, true]) {
    for (final size in [const Size(390, 844), const Size(1024, 768)]) {
      testWidgets('modal filtra y aplica precio comercial=$comercial $size', (
        t,
      ) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        Get.reset();
        SharedPreferences.setMockInitialValues({});
        final api = PedidosOpcionesAdapter()..comercial = comercial;
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

        final producto = Product.fromJson({
          ...PedidosAdapter.product,
          'preciosVenta': [
            {
              'id': 101,
              'precio': 14.0,
              'tipoPrecio': 'POR_DEFECTO',
              'nombre': 'Base tradicional',
            },
            {
              'id': 102,
              'precio': 12.0,
              'tipoPrecio': 'MAYOREO',
              'nombre': 'Mayoreo tradicional',
            },
            {
              'id': 103,
              'precio': 901.0,
              'tipoPrecio': 'ESPECIAL',
              'puntoVenta': {'id': 2},
            },
            {
              'id': 201,
              'precio': 6.0,
              'tipoPrecio': 'POR_DEFECTO',
              'tipoComercialId': 1,
            },
            {
              'id': 202,
              'precio': 5.5,
              'tipoPrecio': 'MAYOREO',
              'tipoComercialId': 2,
            },
            {
              'id': 203,
              'precio': 5.25,
              'tipoPrecio': 'MAYOREO',
              'tipoComercialId': 2,
              'puntoVenta': {'id': 1, 'nombre': 'Sede actual'},
            },
            {
              'id': 204,
              'precio': 902.0,
              'tipoPrecio': 'MAYOREO',
              'tipoComercialId': 2,
              'puntoVenta': {'id': 2},
            },
            {
              'id': 205,
              'precio': 903.0,
              'tipoPrecio': 'POR_DEFECTO',
              'tipoComercialId': 1,
              'eliminado': true,
            },
            {
              'id': 206,
              'precio': 904.0,
              'tipoPrecio': 'MAYOREO',
              'tipoComercialId': 2,
              'estado': false,
            },
            {
              'id': 207,
              'precio': 905.0,
              'tipoPrecio': 'ESPECIAL',
              'tipoComercialId': 99,
            },
          ],
        });
        Navigator.of(t.element(find.byType(ProductsSaleScreen))).push(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              body: SingleChildScrollView(
                child: ModalProductView(product: producto, index: 0),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        for (final prohibido in [
          '901.00',
          '902.00',
          '903.00',
          '904.00',
          '905.00',
        ]) {
          expect(find.text(prohibido), findsNothing);
        }
        if (comercial) {
          expect(find.text('14.00'), findsNothing);
          expect(find.text('12.00'), findsNothing);
          expect(find.byTooltip('Aplicar Mayorista'), findsNWidgets(2));
          await t.ensureVisible(find.byTooltip('Aplicar Mayorista').last);
          await t.tap(find.byTooltip('Aplicar Mayorista').last);
        } else {
          expect(find.text('5.50'), findsNothing);
          expect(find.text('5.25'), findsNothing);
          expect(find.byTooltip('Aplicar Mayoreo tradicional'), findsNothing);
          await t.ensureVisible(find.byTooltip('Aplicar Base tradicional'));
          await t.tap(find.byTooltip('Aplicar Base tradicional'));
        }
        await t.pumpAndSettle();
        var linea = container.read(productSaleProvider).productsSales.single;
        expect(
          linea.precioVentaUnitario,
          closeTo(comercial ? 5.25 : 14, .00001),
        );
        expect(linea.tipoComercialId, comercial ? 2 : isNull);
        if (comercial) {
          expect(linea.productoPrecioId, 203);
          expect(linea.toJson()['productoPrecioId'], 203);
          expect(linea.toJson()['tipoComercialId'], 2);
          expect(linea.tipoComercialCategoria, 'MAYOREO');
          expect(linea.origenPrecio, 'ACCIONES');
          container
              .read(productSaleProvider.notifier)
              .setCantidadProductSale(0, 3);
          await t.pumpAndSettle();
          linea = container.read(productSaleProvider).productsSales.single;
          expect(linea.precioVentaUnitario, closeTo(5.25, .00001));
          expect(linea.productoPrecioId, 203);
          expect(linea.toJson()['productoPrecioId'], 203);
          expect(linea.toJson()['tipoComercialId'], 2);
        }
        await t.pump(const Duration(seconds: 2));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      });
    }
  }
}
