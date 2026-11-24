import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';
import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/config.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/order_restaurant.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/domain/repositories/inventory_repository.dart';
import 'package:teki_app/src/domain/repositories/products_repository.dart';
import 'package:teki_app/src/domain/repositories/restaurant_repository.dart';
import 'package:teki_app/src/providers/restaurant/comanda_provider.dart';
import 'package:teki_app/src/shared/services/command_print_service.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import '../support/command_print_fixture.dart';

class _Restaurant implements RestaurantRepository {
  int creates = 0;
  bool missingId = false;
  bool fail = false;
  Future<void>? gate;
  OrderRestaurant? saved;
  @override
  Future<OrderRestaurant> createOrder(OrderRestaurant order) async {
    creates++;
    saved = order;
    if (gate != null) await gate;
    if (fail) throw StateError('No se pudo guardar pedido QA');
    return OrderRestaurant(
      id: 101,
      comandas: [Command(id: missingId ? null : 501)],
    );
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Products implements ProductsRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Inventory implements InventoryRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  late CommandPrintFixtureAdapter adapter;
  late _Restaurant repo;
  late ProviderContainer container;
  late ComandaNotifier notifier;
  setUp(() {
    dotenv.loadFromString(
      envString:
          'API_URL=https://example.invalid/api\nPRINT_URL=https://print.example.invalid',
    );
    adapter = CommandPrintFixtureAdapter();
    ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
      ..httpClientAdapter = adapter;
    repo = _Restaurant();
    container = ProviderContainer(
      overrides: [
        comandaProvider.overrideWith(
          (ref) => ComandaNotifier(
            ref: ref,
            repository: repo,
            productsRepository: _Products(),
            inventoryRepository: _Inventory(),
          ),
        ),
      ],
    );
    notifier = container.read(comandaProvider.notifier);
    notifier.addCartItem(
      CartItem.create(
        product: Product.fromJson(commandPrintProduct(1, 1, 'COCINA')),
        quantity: 1,
        price: 10,
      ),
    );
  });
  tearDown(() => container.dispose());
  Future<OrderRestaurant?> submit({
    bool? enabled = true,
    String client = 'COFFE',
  }) => notifier.submitPedidoSinMesa(
    puntoVenta: Office(id: 1, codigo: 'QA'),
    config: ConfigCompany(
      clienteImpresion: client,
      imprimirPedidoComandaSinComprobante: enabled,
    ),
    idCompany: 77,
    tipo: 'PEDIDO_LOCAL',
    nombreCliente: 'Cliente QA',
    tipoDocumentoReceptor: '0',
    numeroDocumentoReceptor: '',
    denominacionReceptor: 'Cliente QA',
    direccionReceptor: '',
    emailReceptor: '',
    telefonoReceptor: '',
  );
  Future<void> host(WidgetTester t) async {
    await t.pumpWidget(
      ToastificationWrapper(child: MaterialApp(home: Scaffold())),
    );
    await t.pumpAndSettle();
  }

  Future<void> close(WidgetTester t) async {
    toastification.dismissAll(delayForAnimation: false);
    await t.pump(const Duration(seconds: 1));
    await t.pumpWidget(const SizedBox());
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    await t.pumpAndSettle();
  }

  test('config conserva flag true/false/ausente en roundtrip de sesión', () {
    for (final flag in [true, false, null]) {
      final config = ConfigCompany.fromJson({
        'imprimirPedidoComandaSinComprobante': flag,
      });
      expect(
        ConfigCompany.fromJson(
          config.toJson(),
        ).imprimirPedidoComandaSinComprobante,
        flag,
      );
    }
  });
  test(
    'pedido sin mesa guardado dispara cocina/bar una vez con config activa',
    () async {
      final created = await submit();
      expect(created?.id, 101);
      expect(repo.saved?.mesa, isNull);
      expect(repo.creates, 1);
      expect(adapter.jobs.map((j) => j['printerName']), ['COCINA', 'BAR']);
      expect(adapter.jobs.every((j) => j['idCompany'] == 77), isTrue);
      expect(notifier.state.isSubmitting, isFalse);
    },
  );
  for (final flag in [false, null]) {
    test('flag $flag no imprime, pero sí guarda pedido', () async {
      expect((await submit(enabled: flag))?.id, 101);
      expect(repo.creates, 1);
      expect(adapter.requests, isEmpty);
    });
  }
  test('otro cliente de impresión no genera llamadas COFFE', () async {
    expect((await submit(client: 'BLUETOOTH_BLE'))?.id, 101);
    expect(adapter.requests, isEmpty);
  });
  test(
    'dos toques con impresión pendiente no duplican orden ni trabajos',
    () async {
      final gate = Completer<void>();
      adapter.printGate = gate.future;
      final first = submit();
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.isSubmitting, isTrue);
      expect(await submit(), isNull);
      expect(repo.creates, 1);
      gate.complete();
      expect((await first)?.id, 101);
      expect(adapter.jobs, hasLength(2));
      expect(notifier.state.isSubmitting, isFalse);
    },
  );
  test(
    'salir durante guardado no pierde impresión ni toca estado destruido',
    () async {
      final gate = Completer<void>();
      repo.gate = gate.future;
      final pending = submit();
      container.invalidate(comandaProvider);
      gate.complete();
      expect((await pending)?.id, 101);
      expect(adapter.jobs, hasLength(2));
    },
  );
  for (final falseResult in [false, true]) {
    testWidgets(
      'fallo ${falseResult ? "printed=false" : "HTTP503"} conserva orden y permite reimprimir sin crear otra',
      (t) async {
        await host(t);
        (falseResult ? adapter.offlinePrinters : adapter.failPrinters).add(
          'COCINA',
        );
        final created = await t.runAsync(submit);
        expect(created?.id, 101);
        expect(repo.creates, 1);
        expect(notifier.state.isSubmitting, isFalse);
        await t.pump();
        await t.pump(const Duration(milliseconds: 500));
        await t.pumpAndSettle();
        expect(
          find.text(
            falseResult
                ? 'Agente QA no disponible'
                : 'Impresora QA sin conexión',
          ),
          findsOneWidget,
        );
        adapter.failPrinters.clear();
        adapter.offlinePrinters.clear();
        await t.runAsync(
          () => CommandPrintService().processCommand(
            commandId: 501,
            puntoVenta: Office(id: 1, codigo: 'QA'),
            escPos: false,
            clientPrinter: 'COFFE',
            idCompany: 77,
          ),
        );
        expect(repo.creates, 1);
        expect(adapter.jobs, hasLength(4));
        await close(t);
      },
    );
  }
  testWidgets('respuesta sin comanda identificada avisa y conserva el pedido', (
    t,
  ) async {
    await host(t);
    repo.missingId = true;
    expect((await t.runAsync(submit))?.id, 101);
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    await t.pumpAndSettle();
    expect(
      find.text(
        'Pedido registrado, pero no se encontró la comanda para imprimir.',
      ),
      findsOneWidget,
    );
    expect(repo.creates, 1);
    expect(adapter.jobs, isEmpty);
    await close(t);
  });
  testWidgets('fallo de creación no intenta imprimir y libera el loader', (
    t,
  ) async {
    await host(t);
    repo.fail = true;
    expect(await t.runAsync(submit), isNull);
    expect(adapter.requests, isEmpty);
    expect(notifier.state.isSubmitting, isFalse);
    await close(t);
  });
}
