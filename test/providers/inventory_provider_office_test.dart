import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/response/inventory_record_response.dart';
import 'package:teki_app/src/data/models/response/inventory_response.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';
import 'package:teki_app/src/domain/repositories/inventory_repository.dart';
import 'package:teki_app/src/providers/inventory/inventory_provider.dart';

void main() {
  test('la búsqueda usa el punto de venta recibido explícitamente', () async {
    final repository = _RecordingInventoryRepository();
    final notifier = InventoryNotifier(inventoryRepository: repository);

    await notifier.loadInventory(10);
    await notifier.searchInventory('arroz', idPuntoVenta: 20);

    expect(repository.requests.last['idPuntoVenta'], 20);
    expect(repository.requests.last['clave'], 'arroz');
    expect(notifier.state.idPuntoVenta, 20);
  });

  test(
    'una respuesta anterior no reemplaza el inventario de la sede nueva',
    () async {
      final oldResponse = Completer<InventoryResponse>();
      final repository = _RecordingInventoryRepository(
        responseForOffice: (officeId) {
          if (officeId == 10) return oldResponse.future;
          return Future.value(_response(items: [Inventory(id: 20)]));
        },
      );
      final notifier = InventoryNotifier(inventoryRepository: repository);

      final firstLoad = notifier.loadInventory(10);
      await notifier.loadInventory(20);
      oldResponse.complete(_response(items: [Inventory(id: 10)]));
      await firstLoad;

      expect(notifier.state.idPuntoVenta, 20);
      expect(notifier.state.items.single.id, 20);
    },
  );
}

InventoryResponse _response({List<Inventory> items = const []}) =>
    InventoryResponse(
      content: items,
      empty: items.isEmpty,
      first: true,
      last: true,
      number: 0,
      size: items.length,
      totalElements: items.length,
      totalPages: 1,
      sort: null,
      pageable: null,
    );

class _RecordingInventoryRepository implements InventoryRepository {
  final List<Map<String, dynamic>> requests = [];
  final Future<InventoryResponse> Function(int officeId)? responseForOffice;

  _RecordingInventoryRepository({this.responseForOffice});

  @override
  Future<InventoryResponse> getInventory(Map<String, dynamic> params) {
    requests.add(Map<String, dynamic>.from(params));
    final officeId = params['idPuntoVenta'] as int;
    return responseForOffice?.call(officeId) ?? Future.value(_response());
  }

  @override
  Future<Map<int, Inventory>> getInventoryByProductIds(
    List<int> productIds, {
    required int idPuntoVenta,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<InventoryRecordResponse> getInventoryLogs(
    int idInventory,
    Map<String, dynamic> params,
  ) {
    throw UnimplementedError();
  }
}
