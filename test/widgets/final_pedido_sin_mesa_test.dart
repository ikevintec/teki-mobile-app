import 'dart:convert';
import 'package:toastification/toastification.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart' hide Table;
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: implementation_imports
import 'package:google_fonts/src/google_fonts_base.dart' as fonts;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/table.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/check.dart';
import 'package:teki_app/src/domain/repositories/products_repository.dart';
import 'package:teki_app/src/domain/repositories/inventory_repository.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/comprobante_screen/view_comprobante_screen.dart';
import 'package:teki_app/src/presentation/screens/restaurant/comanda/comanda_screen.dart';
import 'package:teki_app/src/presentation/screens/viewer/pdf_viewer_screen.dart';
import 'package:teki_app/src/presentation/widgets/celebration/success_celebration_overlay.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/restaurant/comanda_provider.dart';
import 'package:teki_app/src/providers/restaurant/direct_checkout/direct_checkout_service.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import '../support/direct_checkout_fixture.dart';
import '../support/restaurant_fixture.dart';

Ticket comprobante() => Ticket(
  id: 9,
  uuid: 'qa-ticket',
  identificadorDocumento: 'N001-524',
  tipoComprobante: 'NV',
  serie: 'N001',
  numero: 524,
  denominacionReceptor: 'Cliente QA',
  codigoMoneda: 'PEN',
  totalVenta: 19.43,
  totalValorVentaGravada: 16.47,
  totalIgv: 2.96,
);

class FinalCheckout extends CheckoutService {
  @override
  Future<bool> claimPrinting(String scope, String operationId) async => true;
  @override
  Future<DirectCheckoutResult> submit(Map<String, dynamic> request) async {
    final result = await super.submit(request);
    return DirectCheckoutResult(
      result.order,
      Check(id: 8, comprobante: comprobante()),
      result.replayed,
      result.action,
      checkoutData: request,
    );
  }
}

class FinalAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.method == 'GET' && options.path == '/orders-restaurant') {
      return ResponseBody.fromString(
        jsonEncode({'content': [], 'last': true, 'totalElements': 0}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    throw StateError('HTTP inesperado: ${options.method} ${options.path}');
  }

  @override
  void close({bool force = false}) {}
}

class FinalSession extends CheckoutSession {
  FinalSession({bool salesPermission = false}) {
    state = state.copyWith(roles: salesPermission ? ['VENTAS_CREAR'] : []);
  }
}

class MenuProducts extends Fake implements ProductsRepository {
  @override
  Future<List<Product>> searchProducts(Map<String, dynamic> params) async => [];
}

class MenuInventory extends Fake implements InventoryRepository {}

class MenuNotifier extends ComandaNotifier {
  MenuNotifier(Ref ref)
    : super(
        ref: ref,
        repository: RestaurantFixture(),
        productsRepository: MenuProducts(),
        inventoryRepository: MenuInventory(),
      );
  @override
  Future<void> init(Table? table, {int? existingOrderId}) async {
    await super.init(table, existingOrderId: existingOrderId);
    // Only first menu starts with a cart; opening Nuevo pedido must clear it.
    if (initializations++ == 0) {
      addCartItem(
        CartItem(
          id: 'qa-item',
          product: Product(id: 3, nombre: 'Producto QA'),
          quantity: 1,
          price: 19.43,
        ),
      );
    }
  }

  int initializations = 0;
}

Future<void> preparar() async {
  Get.reset();
  Get.testMode = true;
  SharedPreferences.setMockInitialValues({});
  GoogleFonts.config.allowRuntimeFetching = false;
  fonts.assetManifest = TestManifest();
  for (final family in [
    'Roboto',
    'Roboto_regular',
    'Roboto_medium',
    'Roboto_semiBold',
    'Roboto_bold', 'Roboto_500', 'Roboto_600', 'Roboto_700',
  ]) {
    final font = FontLoader(family)
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    await font.load();
  }
  dotenv.loadFromString(envString: 'API_URL=https://example.invalid/api');
  ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
    ..httpClientAdapter = FinalAdapter();
}

Future<ProviderContainer> abrir(
  WidgetTester t,
  FinalCheckout service, {
  bool sale = false,
  bool history = false,
  bool salesPermission = false,
}) async {
  final container = ProviderContainer(
    overrides: [
      sesionProvider.overrideWith(
        (_) => FinalSession(salesPermission: salesPermission),
      ),
      directCheckoutServiceProvider.overrideWithValue(service),
      comandaProvider.overrideWith((ref) => MenuNotifier(ref)),
    ],
  );
  await t.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: ToastificationWrapper(
        child: GetMaterialApp(
          theme: ThemeData(fontFamily: 'Roboto'),
          initialRoute: AppRoutes.dashboard,
          getPages: [
            GetPage(
              name: AppRoutes.dashboard,
              page: () => const Scaffold(body: Text('Inicio QA')),
            ),
            GetPage(
              name: AppRoutes.ordersRestaurant,
              page: () => const Scaffold(body: Text('Pedidos QA')),
            ),
            GetPage(
              name: AppRoutes.comprobantesVer,
              page: () => const Scaffold(body: Text('Comprobantes QA')),
            ),
            GetPage(
              name: AppRoutes.productsSales,
              page: () => const Scaffold(body: Text('Venta nueva QA')),
            ),
          ],
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
  if (sale || history) {
    Get.to(() => ViewComponentScreen(ticket: comprobante(), fromSale: sale));
  } else {
    Get.toNamed(AppRoutes.ordersRestaurant);
    await t.pumpAndSettle();
    Get.to(() => const ComandaScreen(isPedidoSinMesa: true));
  }
  await t.pumpAndSettle();
  return container;
}

Future<void> emitir(WidgetTester t) async {
  await t.tap(find.text('Completar pedido').last);
  await t.pumpAndSettle();
  await t.ensureVisible(find.text('Emitir comprobante'));
  await t.tap(find.text('Emitir comprobante'));
  await t.pumpAndSettle();
  expect(find.byType(ViewComponentScreen), findsOneWidget);
  expect(find.byType(PdfViewerScreen), findsNothing);
  expect(find.byType(AnimatedSuccessCheck), findsOneWidget);
  expect(
    t
        .widget<SuccessCelebrationOverlay>(
          find.byType(SuccessCelebrationOverlay),
        )
        .show,
    isTrue,
  );
  expect(find.text('N001 - 524'), findsOneWidget);
  expect(find.text('Nuevo pedido'), findsOneWidget);
  expect(find.text('Pedidos'), findsOneWidget);
  expect(find.text('Nueva venta'), findsNothing);
  expect(find.text('Comprobantes'), findsNothing);
}

void main() {
  setUp(preparar);
  tearDown(Get.reset);
  for (final width in [320.0, 390.0, 1024.0]) {
    testWidgets(
      'pedido final $width: éxito y nuevo pedido vacío sin repetir emisión',
      (t) async {
        t.view.physicalSize = Size(width, width > 500 ? 1366 : 844);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final service = FinalCheckout();
        final c = await abrir(t, service);
        await emitir(t);
        expect(service.sent, hasLength(1));
        await t.tap(find.text('Nuevo pedido'));
        await t.pumpAndSettle();
        expect(find.byType(ComandaScreen), findsOneWidget);
        expect(c.read(comandaProvider).cartItems, isEmpty);
        expect(c.read(comandaProvider).table, isNull);
        expect(service.sent, hasLength(1));
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox.shrink());
        c.dispose();
      },
    );
  }
  for (final action in ['Pedidos', 'Inicio', 'Atrás']) {
    testWidgets('pedido: $action navega sin reemitir', (t) async {
      final s = FinalCheckout();
      final c = await abrir(t, s);
      await emitir(t);
      if (action == 'Atrás') {
        await t.tap(find.byIcon(Icons.chevron_left));
      } else {
        await t.tap(find.text(action));
      }
      await t.pumpAndSettle();
      expect(
        find.text(action == 'Inicio' ? 'Inicio QA' : 'Pedidos QA'),
        findsOneWidget,
      );
      expect(find.byType(ViewComponentScreen), findsNothing);
      expect(s.sent, hasLength(1));
      await t.pumpWidget(const SizedBox.shrink());
      c.dispose();
    });
  }
  for (final sale in [false, true]) {
    testWidgets('PDF manual y celebración en ${sale ? 'venta' : 'pedido'}', (
      t,
    ) async {
      final s = FinalCheckout();
      final c = await abrir(t, s, sale: sale);
      if (!sale) await emitir(t);
      expect(find.text(sale ? 'Nueva venta' : 'Nuevo pedido'), findsOneWidget);
      for (final label in ['Enviar', 'PDF', 'Compartir']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(
        t
            .widget<SuccessCelebrationOverlay>(
              find.byType(SuccessCelebrationOverlay),
            )
            .show,
        isTrue,
      );
      await t.ensureVisible(find.text('PDF'));
      await t.tap(find.text('PDF'));
      await t.pumpAndSettle();
      expect(find.text('Ver formato A4'), findsOneWidget);
      expect(find.text('Ver formato Ticket'), findsOneWidget);
      expect(find.byType(PdfViewerScreen), findsNothing);
      Navigator.of(t.element(find.text('Ver formato A4'))).pop();
      await t.pumpAndSettle();
      await t.tap(find.text(sale ? 'Comprobantes' : 'Pedidos'));
      await t.pumpAndSettle();
      expect(
        find.text(sale ? 'Comprobantes QA' : 'Pedidos QA'),
        findsOneWidget,
      );
      expect(s.sent, hasLength(sale ? 0 : 1));
      await t.pumpWidget(const SizedBox.shrink());
      c.dispose();
    });
  }
  for (final allowed in [false, true]) {
    testWidgets('Nueva venta conserva permiso y navegación: $allowed', (
      t,
    ) async {
      final s = FinalCheckout();
      final c = await abrir(t, s, sale: true, salesPermission: allowed);
      await t.tap(find.text('Nueva venta'));
      await t.pumpAndSettle();
      expect(
        find.text('Venta nueva QA'),
        allowed ? findsOneWidget : findsNothing,
      );
      expect(
        find.byType(ViewComponentScreen),
        allowed ? findsNothing : findsOneWidget,
      );
      expect(s.sent, isEmpty);
      await t.pump(const Duration(seconds: 3)); await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
      c.dispose();
    });
  }
  testWidgets('histórico no añade celebración ni botones de finalización', (
    t,
  ) async {
    final c = await abrir(t, FinalCheckout(), history: true);
    expect(find.byType(AnimatedSuccessCheck), findsNothing);
    expect(
      t
          .widget<SuccessCelebrationOverlay>(
            find.byType(SuccessCelebrationOverlay),
          )
          .show,
      isFalse,
    );
    for (final s in [
      'Nueva venta',
      'Nuevo pedido',
      'Pedidos',
      'Comprobantes',
    ]) {
      expect(find.text(s), findsNothing);
    }
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });
}
