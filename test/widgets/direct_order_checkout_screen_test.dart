import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/teki_model/customer.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/payment_detail.dart';
import 'package:teki_app/src/data/models/teki_model/payment_method.dart';
import 'package:teki_app/src/data/models/teki_model/cash_register_detail.dart';
import 'package:teki_app/src/presentation/screens/sale/sale_info/widget/payment_widget.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import 'package:teki_app/src/data/models/teki_model/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
// Existing payment rows use Google Fonts; use only bundled fonts in tests.
// ignore: implementation_imports
import 'package:google_fonts/src/google_fonts_base.dart' as fonts;
import 'package:teki_app/src/data/models/teki_model/order_restaurant.dart';
import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/restaurant/direct_checkout/direct_checkout_service.dart';
import 'package:teki_app/src/presentation/screens/orders_restaurant/widgets/direct_order_checkout_screen.dart';
import '../support/direct_checkout_fixture.dart';
import '../support/dashboard_fixture.dart';

void main() {
  late CheckoutService service;
  setUp(() async {
    service = CheckoutService();
    GoogleFonts.config.allowRuntimeFetching = false;
    fonts.assetManifest = TestManifest();
    final font = await rootBundle.load(
      'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (_) async => font);
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null),
  );

  Future<void> open(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    bool anonymous = false,
    bool generic = false,
    String? recipientName,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sesionProvider.overrideWith(
            (_) => anonymous ? AnonymousSession() : generic ? GenericSession() : CheckoutSession(),
          ),
          directCheckoutServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  final result = await Navigator.of(context)
                      .push<DirectCheckoutResult>(
                        MaterialPageRoute(
                          builder: (_) => DirectOrderCheckoutScreen(
                            order: OrderRestaurant(
                              denominacionReceptor: recipientName,
                              comandas: [
                                Command(
                                  items: [
                                    CommandDetail(
                                      producto: Product(
                                        id: 3,
                                        nombre: 'Producto QA',
                                      ),
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
                      );
                  if (context.mounted && result != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Guardado ${result.action}')),
                    );
                  }
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  for (final initialName in <String?>[null, 'Nombre previo del pedido']) {
    testWidgets('nombre libre restaurante conserva genérico y precarga $initialName', (tester) async {
      dotenv.loadFromString(envString: 'API_URL=https://example.invalid/api');
      ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
        ..httpClientAdapter = DashboardAdapter();
      await open(tester, generic: true, recipientName: initialName);
      final input = find.widgetWithText(TextFormField, 'Nombre o documento');
      await tester.ensureVisible(input);
      await tester.tap(input);
      await tester.pump();
      final controller = tester.widget<TextFormField>(input).controller!;
      expect(controller.text, initialName ?? 'Clientes varios');
      expect(controller.selection, TextSelection(baseOffset: 0, extentOffset: controller.text.length));
      await tester.enterText(input, 'Ana del restaurante');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Emitir comprobante'));
      await tester.tap(find.text('Emitir comprobante'));
      await tester.pumpAndSettle();
      final pedido = service.sent.single['pedido'] as Map;
      expect(pedido['denominacionReceptor'], 'Ana del restaurante');
      expect(pedido['cliente']['id'], 10);
      expect(pedido['cliente']['razonSocial'], 'Clientes varios');
      expect(pedido['cliente']['numeroDocumento'], '-');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'pago final de restaurante carga efectivo recibido y vuelto preparados',
    (tester) async {
      dotenv.loadFromString(envString: 'API_URL=https://example.invalid/api');
      ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
        ..httpClientAdapter = DashboardAdapter();
      final container = ProviderContainer(
        overrides: [sesionProvider.overrideWith((_) => CheckoutSession())],
      );
      addTearDown(container.dispose);
      container
          .read(ticketProvider.notifier)
          .updateTicket(
            Ticket(
              tipoComprobante: 'NV',
              codigoMoneda: 'PEN',
              totalVenta: 19.43,
              cuentaRestaurante: 88,
              movimientoCaja: CashRegisterDetail(
                pagos: [
                  PaymentDetail(
                    metodoPago: PaymentMethod(
                      id: 1,
                      nombre: 'Efectivo',
                      formaPago: 'EFECTIVO',
                    ),
                    formaPago: 'EFECTIVO',
                    monto: 19.43,
                    montoPagado: 50,
                    cambio: 30.57,
                  ),
                ],
              ),
            ),
          );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: PaymentWidget())),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, 'Efectivo recibido'),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is TextFormField && w.controller?.text == '50.00',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('30.57'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  for (final action in {
    'DRAFT': 'Guardar borrador',
    'EDIT': 'Facturación completa',
    'INVOICE': 'Emitir comprobante',
  }.entries) {
    testWidgets('${action.key}: una pantalla y una sola operación', (
      tester,
    ) async {
      await open(tester);
      expect(find.textContaining('Calculando'), findsNothing);
      expect(find.text('S/ 19.43'), findsNWidgets(2));
      expect(find.text('Serie N001 · Automática'), findsOneWidget);
      await tester.tap(find.text(action.value));
      await tester.pumpAndSettle();
      expect(service.sent, hasLength(1));
      expect(service.sent.single['action'], action.key);
      if (action.key == 'INVOICE') {
        expect(service.sent.single['pagos'].single['monto'], 19.43);
        expect(
          service
              .sent
              .single['pedido']['comandas'][0]['items'][0]['precioVenta'],
          7.77,
        );
      }
      expect(find.text('Completar pedido'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final type in ['NV', '03']) {
    testWidgets('$type permite cliente anónimo sin inventar un DNI', (
      tester,
    ) async {
      await open(tester, anonymous: true);
      if (type == '03') {
        service.availableSeries = ['B001'];
        await tester.tap(find.text('Boleta'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Emitir comprobante'));
      await tester.pumpAndSettle();
      expect(service.sent, hasLength(1));
      final order = service.sent.single['pedido'];
      expect(order['cliente']['tipoDocumento'], '0');
      expect(order['cliente']['numeroDocumento'], '-');
      expect(order['cliente']['razonSocial'], 'Clientes varios');
      expect(order['tipoDocumentoReceptor'], '0');
      expect(order['numeroDocumentoReceptor'], '-');
      expect(order['denominacionReceptor'], 'Clientes varios');
    });
  }
  testWidgets(
    'nombre y contacto de pedido anónimo no modifican cliente genérico',
    (tester) async {
      await open(tester, anonymous: true);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre o documento'),
        'AB',
      );
      await tester.ensureVisible(find.text('Dirección y contacto'));
      await tester.tap(find.text('Dirección y contacto'));
      await tester.pumpAndSettle();
      final email = find.widgetWithText(TextFormField, 'Email');
      await tester.ensureVisible(email);
      await tester.enterText(email, 'qa@example.invalid');
      await tester.tap(find.text('Emitir comprobante'));
      await tester.pumpAndSettle();
      final order = service.sent.single['pedido'];
      expect(order['denominacionReceptor'], 'AB');
      expect(order['emailReceptor'], 'qa@example.invalid');
      expect(order['cliente']['razonSocial'], 'Clientes varios');
      expect(order['cliente']['email'], isNull);
      expect(order['cliente']['telefono'], isNull);
    },
  );
  testWidgets(
    'factura exige identificación y muestra dirección fiscal abierta',
    (tester) async {
      await open(tester, anonymous: true);
      await tester.tap(find.text('Factura'));
      await tester.pumpAndSettle();
      expect(find.text('Dirección fiscal'), findsOneWidget);
      await tester.tap(find.text('Emitir comprobante'));
      await tester.pumpAndSettle();
      expect(service.sent, isEmpty);
      expect(find.textContaining('La factura requiere'), findsOneWidget);
    },
  );
  testWidgets('cambiar de factura inválida a nota elimina el error anterior', (
    tester,
  ) async {
    await open(tester, anonymous: true);
    await tester.tap(find.text('Factura'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Emitir comprobante'));
    await tester.pumpAndSettle();
    expect(find.textContaining('La factura requiere'), findsOneWidget);
    await tester.ensureVisible(find.text('Nota de venta'));
    await tester.tap(find.text('Nota de venta'));
    await tester.pumpAndSettle();
    expect(find.textContaining('La factura requiere'), findsNothing);
    expect(service.sent, isEmpty);
  });

  testWidgets(
    'corregir el efectivo recibido elimina el error de pago anterior',
    (tester) async {
      await open(tester);
      final cash = find
          .widgetWithText(TextFormField, 'Efectivo recibido')
          .first;
      await tester.ensureVisible(cash);
      await tester.enterText(cash, '1');
      await tester.ensureVisible(find.text('Emitir comprobante'));
      await tester.tap(find.text('Emitir comprobante'));
      await tester.pumpAndSettle();
      expect(
        find.text('El monto pagado es menor al total de la venta'),
        findsOneWidget,
      );
      await tester.ensureVisible(cash);
      await tester.enterText(cash, '19.43');
      await tester.pumpAndSettle();
      expect(
        find.text('El monto pagado es menor al total de la venta'),
        findsNothing,
      );
      expect(service.sent, isEmpty);
    },
  );

  testWidgets('recuperación permite salir, reabrir y recuperar el mismo UUID', (
    tester,
  ) async {
    await open(tester);
    service.loseResponse = true;
    await tester.tap(find.text('Emitir comprobante'));
    await tester.pumpAndSettle();
    expect(find.text('Continuar después'), findsOneWidget);
    await tester.tap(find.text('Continuar después'));
    await tester.pumpAndSettle();
    expect(find.text('Abrir'), findsOneWidget);
    expect(service.stored, isNotNull);
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Recuperar pedido'), findsOneWidget);
    service.loseResponse = false;
    await tester.tap(find.text('Recuperar pedido'));
    await tester.pumpAndSettle();
    expect(service.sent[0], service.sent[1]);
    expect(service.stored, isNull);
  });
  testWidgets('tema de pedidos conserva identidad azul y fondo blanco', (
    tester,
  ) async {
    await open(tester);
    final theme = Theme.of(tester.element(find.byType(Form)));
    expect(theme.colorScheme.primary, const Color(0xFF2C6AE5));
    expect(theme.scaffoldBackgroundColor, Colors.white);
  });
  testWidgets('sin series se explica la causa y recuperar habilita emitir', (
    tester,
  ) async {
    service.availableSeries = [];
    await open(tester);
    expect(
      find.text('No hay series disponibles en esta sede.'),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    service.availableSeries = ['N001'];
    await tester.tap(find.text('Actualizar total'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  for (final size in [const Size(320, 568), const Size(820, 1180)]) {
    testWidgets('viewport $size conserva acciones y formulario sin overflow', (
      tester,
    ) async {
      await open(tester, size: size);
      expect(find.text('Guardar borrador'), findsOneWidget);
      expect(find.text('Facturación completa'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Delivery'));
      await tester.pumpAndSettle();
      expect(find.text('Dirección de entrega'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'timeout bloquea edición y recupera exactamente el mismo pedido',
    (tester) async {
      await open(tester);
      service.loseResponse = true;
      await tester.tap(find.text('Emitir comprobante'));
      await tester.pumpAndSettle();
      expect(find.text('Recuperar pedido'), findsOneWidget);
      expect(find.text('Guardar borrador'), findsNothing);
      service.loseResponse = false;
      await tester.tap(find.text('Recuperar pedido'));
      await tester.pumpAndSettle();
      expect(service.sent[0], service.sent[1]);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('pago mixto, vuelto y propina conservan importes y responsable', (
    tester,
  ) async {
    await open(tester);
    final cash = find.byWidgetPredicate(
      (w) => w is TextFormField && w.controller?.text == '19.43',
    );
    await tester.ensureVisible(cash);
    await tester.enterText(cash, '30');
    await tester.ensureVisible(find.text('Yape'));
    await tester.tap(find.text('Yape'));
    await tester.pumpAndSettle();
    final nonCash = find.byWidgetPredicate(
      (w) => w is TextFormField && w.controller?.text == '0.00',
    );
    await tester.ensureVisible(nonCash);
    await tester.enterText(nonCash, '7.43');
    await tester.ensureVisible(find.text('Agregar propina'));
    await tester.tap(find.text('Agregar propina'));
    await tester.pumpAndSettle();
    final tip = find.widgetWithText(TextFormField, 'Propina');
    await tester.ensureVisible(tip);
    await tester.enterText(tip, '6');
    await tester.pumpAndSettle();
    await tester.enterText(tip, '5');
    await tester.pumpAndSettle();
    expect(find.text('Vuelto: S/ 18.00'), findsOneWidget);
    final waiter = find.byType(DropdownButtonFormField<int>);
    await tester.ensureVisible(waiter);
    await tester.tap(waiter);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Responsable QA').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Emitir comprobante'));
    await tester.pumpAndSettle();
    expect(service.sent, hasLength(1));
    final request = service.sent.single;
    expect(request['propina'], 5);
    expect(request['idMozo'], 3);
    expect(request['pagos'][0]['monto'], 12);
    expect(request['pagos'][0]['montoPagado'], 30);
    expect(request['pagos'][0]['cambio'], 18);
    expect(request['pagos'][1]['monto'], 7.43);
    expect(request['pagosPropina'][0]['monto'], 5);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'teclado en teléfono pequeño conserva la acción principal sin overflow',
    (tester) async {
      await open(tester, size: const Size(320, 568));
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(find.text('Emitir comprobante'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class AnonymousSession extends CheckoutSession {
  AnonymousSession() {
    state = state.copyWith(
      config: ConfigCompany.fromJson({
        ...state.config!.toJson(),
        'clientePorDefecto': false,
      }),
    );
  }
}

class GenericSession extends CheckoutSession {
  GenericSession() {
    state.config!.clientePorDefectoData = Customer(id: 10, razonSocial: 'Clientes varios',
      tipoDocumento: '0', numeroDocumento: '-', porDefecto: true);
  }
}
