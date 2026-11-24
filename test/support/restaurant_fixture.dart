import 'package:teki_app/src/data/models/teki_model/check.dart';
import 'package:teki_app/src/data/models/teki_model/lounge.dart';
import 'package:teki_app/src/data/models/teki_model/order_restaurant.dart';
import 'package:teki_app/src/data/models/teki_model/table.dart';
import 'package:teki_app/src/domain/repositories/restaurant_repository.dart';

class RestaurantFixture implements RestaurantRepository {
  int checkCalls = 0;
  final checks = <Check>[
    Check.fromJson({
      'id': 701,
      'pedido': {
        'id': 101,
        'tipo': 'LOCAL',
        'mesa': {'id': 11, 'numero': 1},
      },
      'items': [
        {
          'id': 1,
          'producto': {'nombre': 'Lomo QA'},
          'cantidad': 2.0,
          'precioVenta': 25.0,
          'estadoComandaDetalle': 'PENDIENTE',
        },
        {
          'id': 2,
          'producto': {'nombre': 'Cancelado QA'},
          'cantidad': 1.0,
          'precioVenta': 99.0,
          'estadoComandaDetalle': 'CANCELADO',
        },
        {
          'id': 3,
          'producto': {'nombre': 'Rechazado QA'},
          'cantidad': 1.0,
          'precioVenta': 88.0,
          'estadoComandaDetalle': 'RECHAZADO',
        },
        {
          'id': 4,
          'producto': {'nombre': 'Eliminado QA'},
          'cantidad': 1.0,
          'precioVenta': 77.0,
          'eliminado': true,
        },
      ],
    }),
  ];
  final tables = <Table>[
    Table.fromJson({
      'id': 11,
      'numero': 3,
      'llamadaEn': '2026-11-24T10:00:00-05:00',
      'salon': {'id': 1, 'nombre': 'Salón principal'},
      'pedidoActual': {
        'id': 101,
        'estado': 'PENDIENTE',
        'sinMozoAsignado': true,
        'esPedidoQr': true,
        'fecha': '2026-11-24T10:00:00-05:00',
      },
    }),
  ];

  @override
  Future<List<Check>> getChecks(Map<String, dynamic> params) async {
    checkCalls++;
    return checks;
  }

  @override
  Future<List<Lounge>> getLounges(Map<String, dynamic> params) async => [
    Lounge(id: 1, nombre: 'Salón principal'),
  ];
  @override
  Future<List<Table>> getTables(Map<String, dynamic> params) async => tables;
  @override
  Future<List<OrderRestaurant>> getOrders(Map<String, dynamic> params) async =>
      [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
