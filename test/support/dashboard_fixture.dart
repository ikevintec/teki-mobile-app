import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/sale_station.dart';
import 'loyalty_fixture.dart';

SesionState dashboardSession({
  List<String> roles = const ['SUPER_USUARIO'],
  bool features = true,
}) {
  final base = loyaltySession(
    roles: roles,
    enabled: features,
    containers: features,
  );
  base.config!.inventario = features;
  base.config!.esRestaurante = features;
  base.config!.verNotificacionYape = features;
  return SesionState(
    login: base.login,
    company: base.company,
    companySelected: base.companySelected,
    roles: roles,
    config: base.config,
    office: Office(id: 1, nombre: 'Local de demostración'),
    saleStation: SaleStation(id: 1, nombre: 'Caja de prueba'),
  );
}

/// Intercepta toda la red: la vista de prueba nunca usa la API de producción.
class DashboardAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    requests.add(options);
    Object result;
    switch (options.path) {
      case '/tickets':
        result = [
          {
            'id': 1,
            'totalVenta': 120.0,
            'codigoMoneda': 'PEN',
            'tipoComprobante': 'NV',
          },
        ];
      case '/cash-register':
        result = [
          {
            'id': 1,
            'fecha': DateTime.now().millisecondsSinceEpoch,
            'estadoCaja': 'APERTURADA',
            'puntoVenta': {'id': 1},
            'estacionVenta': {'id': 1},
          },
        ];
      case '/customers':
        result = [
          {
            'id': 1,
            'razonSocial': 'Cliente de demostración',
            'numeroDocumento': '00000001',
          },
        ];
      default:
        // No se puede alcanzar una red externa desde este adaptador.
        result = [];
    }
    return ResponseBody.fromString(
      jsonEncode(result),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
