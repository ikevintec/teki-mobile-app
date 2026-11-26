import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/response/login.dart';
import 'package:teki_app/src/data/models/teki_model/company_summary.dart';
import 'package:teki_app/src/data/models/teki_model/config.dart';
import 'package:teki_app/src/data/models/teki_model/customer.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/payment_method.dart';
import 'package:teki_app/src/data/models/teki_model/sale_station.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/data/models/teki_model/order_restaurant.dart';
import 'package:teki_app/src/domain/repositories/sale_station_repository.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/restaurant/direct_checkout/direct_checkout_service.dart';
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/teki_model/check.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';

Map<String, dynamic> draft({double delivery = 0}) => {
  'pedido': {
    'puntoVenta': {'id': 1},
    'tipo': delivery > 0 ? 'PEDIDO_FORANEO' : 'PEDIDO_LOCAL_INTERNO',
    'montoDelivery': delivery,
    'comandas': [
      {
        'items': [
          {
            'producto': {'id': 3},
            'cantidad': 2.5,
            'precioVenta': 7.77,
            'grupoProductoOpciones': [],
            'preparacionProductoOpciones': [],
          },
        ],
      },
    ],
  },
  'idEstacionVenta': 2,
  'tipoComprobante': 'NV',
  'serie': 'N001',
  'pagos': [
    {'monto': 19.43},
  ],
};

class Service extends DirectCheckoutService {
  Service() : super(dio: Dio());
  Map<String, dynamic>? stored;
  List<Map<String, dynamic>> sent = [];
  List<Completer<Map<String, dynamic>>> previews = [];
  int previewCount = 0;
  bool loseResponse = false;
  bool reject = false;
  bool cleanupFails = false;
  bool storageFails = false;
  bool malformed = false;
  Completer<void>? wait;
  @override
  Future<Map<String, dynamic>?> pending(String scope) async => stored;
  @override
  Future<void> remember(String scope, Map<String, dynamic> request) async {
    if (storageFails) throw StateError('storage');
    stored = Map<String, dynamic>.from(jsonDecode(jsonEncode(request)));
  }

  @override
  Future<void> forget(String scope) async {
    if (cleanupFails) throw StateError('storage');
    stored = null;
  }

  @override
  Future<Map<String, dynamic>> preview(Map<String, dynamic> request) async {
    final index = previewCount++;
    if (previews.length > index) return previews[index].future;
    return {
      'totalVenta': 19.43,
      'totalesPedido': [19.43],
      'codigoMoneda': 'PEN',
    };
  }

  @override
  Future<DirectCheckoutResult> submit(Map<String, dynamic> request) async {
    sent.add(Map<String, dynamic>.from(jsonDecode(jsonEncode(request))));
    if (wait != null) {
      await wait!.future;
    }
    if (loseResponse || reject) {
      throw DioException(
        requestOptions: RequestOptions(path: '/'),
        type: loseResponse
            ? DioExceptionType.receiveTimeout
            : DioExceptionType.badResponse,
        response: reject
            ? Response(
                requestOptions: RequestOptions(path: '/'),
                statusCode: 412,
                data: {'message': 'El total cambió'},
              )
            : null,
      );
    }
    if (malformed) throw StateError('incomplete');
    return DirectCheckoutResult(
      OrderRestaurant(id: 7),
      Check(id: 8, comprobante: Ticket(id: 9)),
      sent.length > 1,
      request['action'],
      checkoutData: request,
    );
  }
}

class Stations extends Fake implements SaleStationRepository {}

class CheckoutSession extends SesionNotifier {
  CheckoutSession() : super(saleStationRepository: Stations()) {
    state = SesionState(
      login: LoginResponse(user: User(id: 2)),
      company: Companysummary(id: 1),
      office: Office(id: 1),
      saleStation: SaleStation(id: 2),
      config: ConfigCompany(
        tipoComprobantePorDefecto: 'NV',
        clientePorDefecto: true,
        excluirIgvNotaVenta: true,
        clientePorDefectoData: Customer(
          razonSocial: 'Cliente QA',
          tipoDocumento: '1',
          numeroDocumento: '11111111',
        ),
        formasPago: [
          PaymentMethod(
            id: 1,
            formaPago: 'EFECTIVO',
            nombre: 'Efectivo',
            tipoMovimiento: 'INGRESO',
          ),
          PaymentMethod(
            id: 2,
            formaPago: 'TRANSFERENCIA',
            nombre: 'Yape',
            tipoMovimiento: 'INGRESO',
          ),
        ],
      ),
    );
  }
}

class CheckoutService extends Service {
  List<String> availableSeries = ['N001'];
  @override
  Future<List<String>> series(int office, String type) async => availableSeries;
  @override
  Future<List<Map<String, dynamic>>> users() async => [
    {'id': 3, 'nombreCompleto': 'Responsable QA'},
  ];
}

class TestManifest implements AssetManifest {
  @override
  List<String> listAssets() => [];
  @override
  List<AssetMetadata>? getAssetVariants(String key) => null;
}
