import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';
import 'package:teki_app/src/data/models/teki_model/config.dart';
import 'package:teki_app/src/data/models/teki_model/company_summary.dart';
import 'package:teki_app/src/data/models/teki_model/customer.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/domain/repositories/quotation_repository.dart';
import 'package:teki_app/src/domain/repositories/tickets_sale_repository.dart';
import 'package:teki_app/src/providers/auth/login.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_provider.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_state.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';

import '../support/command_print_fixture.dart';
import '../support/envase_sale_fixture.dart';

class _Ref extends SaleTestRef {
  @override
  T read<T>(ProviderListenable<T> provider) {
    if (identical(provider, authStateProvider)) {
      return AuthState(isLoggedIn: true) as T;
    }
    if (identical(provider, customerSaleProvider)) {
      return CustomerSaleState(
            customer: Customer(razonSocial: 'Cliente QA'),
            customers: [],
            selectedCustomer: null,
            isLoading: false,
            error: null,
            pageNumber: 0,
            perPage: 20,
            filterGlobal: '',
            totalElements: null,
            paginacion: false,
          )
          as T;
    }
    if (identical(provider, productSaleProvider)) {
      return initial(testLine()) as T;
    }
    return super.read(provider);
  }
}

class _Tickets implements TicketsSaleRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Quotations implements QuotationRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Adapter extends CommandPrintFixtureAdapter {
  int payments = 0;
  bool table = false;
  bool paymentFails = false;
  bool noOrder = false;
  List<int?> commandIds = [501];
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    if (o.path == '/checks/701' && o.method == 'PUT') {
      payments++;
      requests.add(o);
      return response(
        paymentFails
            ? {'message': 'Pago QA rechazado'}
            : {
                'id': 701,
                'pagado': true,
                'comprobante': {'id': 901, 'tipoComprobante': 'NV'},
                if (!noOrder)
                  'pedido': {
                    'id': 101,
                    if (table) 'mesa': {'id': 11},
                    'comandas': [
                      for (final id in commandIds) {'id': id},
                    ],
                  },
              },
        paymentFails ? 503 : 200,
      );
    }
    if (o.path == '/commands/502') {
      requests.add(o);
      return response({'id': 502, 'items': items});
    }
    return super.fetch(o, stream, cancel);
  }
}

void main() {
  late _Adapter adapter;
  late _Ref ref;
  late TicketNotifier notifier;
  setUp(() {
    dotenv.loadFromString(
      envString:
          'API_URL=https://example.invalid/api\nPRINT_URL=https://print.example.invalid',
    );
    adapter = _Adapter();
    ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
      ..httpClientAdapter = adapter;
    ref = _Ref();
    ref.session = testSesion.copyWith(
      company: Companysummary(id: 77),
      office: Office(id: 1, codigo: 'QA'),
      config: ConfigCompany(
        clienteImpresion: 'COFFE',
        imprimirPedidoComandaSinComprobante: false,
      ),
    );
    notifier = TicketNotifier(
      ref: ref,
      ticketsSaleRepository: _Tickets(),
      quotationRepository: _Quotations(),
    );
  });
  tearDown(() => notifier.dispose());

  test(
    'cobro sin mesa con flag apagado envía comanda después de guardar',
    () async {
      expect((await notifier.pagarCuentaRestaurante(701))?.id, 901);
      expect(adapter.payments, 1);
      expect(adapter.requests.first.path, '/checks/701');
      expect(adapter.jobs.every((j) => j['idCompany'] == 77), isTrue);
      expect(adapter.jobs.map((j) => j['printerName']), ['COCINA', 'BAR']);
    },
  );
  test('con mesa no vuelve a enviar la comanda al cobrar', () async {
    adapter.table = true;
    expect((await notifier.pagarCuentaRestaurante(701))?.id, 901);
    expect(adapter.jobs, isEmpty);
  });
  test('flag activo ya imprimió al registrar y no duplica al cobrar', () async {
    ref.session.config!.imprimirPedidoComandaSinComprobante = true;
    expect((await notifier.pagarCuentaRestaurante(701))?.id, 901);
    expect(adapter.jobs, isEmpty);
  });
  test('flag ausente usa impresión posterior al cobro igual que web', () async {
    ref.session.config!.imprimirPedidoComandaSinComprobante = null;
    await notifier.pagarCuentaRestaurante(701);
    expect(adapter.jobs, hasLength(2));
  });
  test('cobra todas las comandas identificadas del pedido', () async {
    adapter.commandIds = [501, 502];
    await notifier.pagarCuentaRestaurante(701);
    expect(adapter.payments, 1);
    expect(adapter.jobs, hasLength(4));
    expect(adapter.jobs.map((j) => j['url']).join(), contains('/command/502?'));
  });
  test('respuesta sin pedido conserva el comprobante sin impresión', () async {
    adapter.noOrder = true;
    expect((await notifier.pagarCuentaRestaurante(701))?.id, 901);
    expect(adapter.jobs, isEmpty);
  });
  test('GLOBAL con ESC-POS activo usa el formato de la empresa', () async {
    ref.session.config!.imprimeTicketsEscPos = true;
    for (final item in adapter.items) {
      final area = item['producto']['categoria']['areaProduccion'] as Map;
      (area['impresoras'] as List).first['tipoImpresion'] = 'GLOBAL';
    }
    await notifier.pagarCuentaRestaurante(701);
    expect(adapter.jobs, hasLength(2));
    expect(adapter.jobs.every((j) => j['event'] == 'printEscPos'), isTrue);
  });
  test('IDs repetidos o ausentes no repiten envíos al cobrar', () async {
    adapter.commandIds = [501, 501, null];
    await notifier.pagarCuentaRestaurante(701);
    expect(adapter.jobs, hasLength(2));
  });
  test('cliente distinto no genera trabajos COFFE', () async {
    ref.session.config!.clienteImpresion = 'BLUETOOTH_BLE';
    expect((await notifier.pagarCuentaRestaurante(701))?.id, 901);
    expect(adapter.jobs, isEmpty);
  });
  for (final failure in ['payment', 'http', 'offline']) {
    final failPayment = failure == 'payment';
    testWidgets(
      failPayment
          ? 'pago fallido no imprime'
          : 'impresora $failure conserva comprobante y no repite cobro',
      (t) async {
        await t.pumpWidget(
          ToastificationWrapper(child: MaterialApp(home: Scaffold())),
        );
        adapter.paymentFails = failPayment;
        if (failure == 'http') adapter.failPrinters.add('COCINA');
        if (failure == 'offline') adapter.offlinePrinters.add('COCINA');
        if (failPayment) {
          await t.runAsync(
            () => expectLater(
              notifier.pagarCuentaRestaurante(701),
              throwsA(anything),
            ),
          );
          expect(adapter.jobs, isEmpty);
        } else {
          final ticket = await t.runAsync(
            () => notifier.pagarCuentaRestaurante(701),
          );
          expect(ticket?.id, 901);
          expect(adapter.jobs.map((j) => j['printerName']), ['COCINA', 'BAR']);
        }
        expect(adapter.payments, 1);
        await t.pumpAndSettle();
        toastification.dismissAll(delayForAnimation: false);
        await t.pump(const Duration(seconds: 1));
        await t.pumpWidget(const SizedBox());
        await t.pumpAndSettle();
      },
    );
  }
}
