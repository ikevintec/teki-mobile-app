import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/check.dart';
import 'package:teki_app/src/data/models/teki_model/customer.dart';
import 'package:teki_app/src/data/models/teki_model/order_restaurant.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_provider.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import '../support/loyalty_fixture.dart';
import '../support/pedidos_fixture.dart';

class CustomerAdapter implements HttpClientAdapter {
  final Customer generic;
  CustomerAdapter(this.generic);
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    final Object data;
    if (o.path == '/currencies') {
      data = [
        {'codigoMoneda': 'PEN', 'tipoCambio': 1.0},
      ];
    } else if (o.path == '/tickets/7' || o.path == '/quotation/8') {
      data = {
        'id': 7,
        'cliente': generic.toJson(),
        'denominacionReceptor': 'Ana del comprobante',
        'numeroDocumentoReceptor': '-',
        'tipoDocumentoReceptor': '0',
        'codigoMoneda': 'PEN',
        'tipoComprobante': 'NV',
        'tipoComprobanteDestino': 'NV',
        'isQuotation': true,
        'incIgv': true,
        'items': [],
      };
    } else {
      throw StateError('HTTP no previsto: ${o.path}');
    }
    return ResponseBody.fromString(
      jsonEncode(data),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late ProviderContainer container;
  late Customer generic;
  setUp(() {
    dotenv.loadFromString(envString: 'API_URL=https://example.invalid/api');
    generic = Customer(
      id: 10,
      razonSocial: 'Clientes varios',
      tipoDocumento: '0',
      numeroDocumento: '-',
      porDefecto: true,
    );
    ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
      ..httpClientAdapter = CustomerAdapter(generic);
    final session = pedidosSession();
    session.config!.clientePorDefectoData = generic;
    session.config!.configuracionDistribuidor = {};
    container = ProviderContainer(
      overrides: [
        sesionProvider.overrideWith((_) => LoyaltySessionNotifier(session)),
      ],
    );
  });
  tearDown(() {
    container.dispose();
    ApiClient.dio.close(force: true);
  });

  void expectName(String name) {
    final customer = container.read(customerSaleProvider).customer;
    expect(customer.razonSocial, name);
    expect(customer.id, 10);
    expect(customer.numeroDocumento, '-');
    container.read(ticketProvider.notifier).setTicketsData();
    expect(
      container.read(ticketProvider).ticket.toJson()['denominacionReceptor'],
      name,
    );
    expect(generic.razonSocial, 'Clientes varios');
    expect(
      container.read(sesionProvider).config!.clientePorDefectoData!.razonSocial,
      'Clientes varios',
    );
  }

  test(
    'editar venta precarga nombre del ticket en vez de ficha genérica',
    () async {
      await container.read(productSaleProvider.notifier).loadInitialData(7);
      expectName('Ana del comprobante');
    },
  );
  test('cotización a venta conserva nombre del receptor', () async {
    await container
        .read(productSaleProvider.notifier)
        .loadInitialData(null, quotationIdForSale: 8);
    expectName('Ana del comprobante');
  });
  test('editar cotización conserva nombre del receptor', () async {
    await container
        .read(productSaleProvider.notifier)
        .loadInitialData(null, quotationId: 8);
    expectName('Ana del comprobante');
  });
  test(
    'restaurante precarga nombre del pedido conservando cliente de cuenta',
    () async {
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
      expectName('Ana del pedido');
    },
  );
  test('cuenta genérica conserva nombre del pedido sin ficha anidada', () async {
    await container.read(productSaleProvider.notifier).initFromCheck(Check(id: 1,
      cliente: generic, pedido: OrderRestaurant(denominacionReceptor: 'Ana del pedido')));
    expectName('Ana del pedido');
  });
  test(
    'restaurante resuelve cliente y nombre desde pedido cuando cuenta no trae cliente',
    () async {
      await container
          .read(productSaleProvider.notifier)
          .initFromCheck(
            Check(
              id: 1,
              pedido: OrderRestaurant(
                cliente: generic,
                nombreCliente: 'Ana para llevar',
              ),
            ),
          );
      expectName('Ana para llevar');
    },
  );
  test(
    'cuenta dividida con cliente diferente no hereda receptor de otra persona',
    () async {
      await container
          .read(productSaleProvider.notifier)
          .initFromCheck(
            Check(
              id: 1,
              cliente: Customer(
                id: 11,
                razonSocial: 'Otro cliente',
                numeroDocumento: '11111111',
              ),
              pedido: OrderRestaurant(
                cliente: generic,
                denominacionReceptor: 'Ana del pedido',
              ),
            ),
          );
      expect(
        container.read(customerSaleProvider).customer.razonSocial,
        'Otro cliente',
      );
    },
  );
  test(
    'receptor ausente usa ficha y una nueva venta recupera nombre por defecto',
    () {
      var notifier = container.read(customerSaleProvider.notifier);
      notifier.setCustomerFromTicket(
        Ticket(cliente: generic, denominacionReceptor: 'Ana'),
      );
      container.invalidate(customerSaleProvider);
      notifier = container.read(customerSaleProvider.notifier);
      notifier.setCustomerFromTicket(Ticket(cliente: generic));
      expectName('Clientes varios');
    },
  );
}
