import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/response/inventory_response.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';
import 'package:teki_app/src/domain/repositories/inventory_repository.dart';
import 'package:teki_app/src/providers/inventory/inventory_provider.dart';

InventoryResponse _page(int id, {bool last = false}) => InventoryResponse(
  content: [Inventory(id: id)],
  empty: false,
  first: id == 1,
  last: last,
  number: 0,
  size: 1,
  totalElements: 2,
  totalPages: 2,
  sort: null,
  pageable: null,
);

class _Repository implements InventoryRepository {
  final calls = <Map<String, dynamic>>[];
  Completer<InventoryResponse>? deferred;
  bool fail = false;
  @override
  Future<InventoryResponse> getInventory(Map<String, dynamic> params) async {
    calls.add(Map.of(params));
    if (fail) throw Exception('offline');
    if (deferred != null) return deferred!.future;
    return _page(calls.length, last: params['pageNumber'] == 1);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('filtros consultan todas las páginas y conservan la búsqueda', () async {
    final repo = _Repository();
    final notifier = InventoryNotifier(inventoryRepository: repo);
    addTearDown(notifier.dispose);
    await notifier.loadInventory(1, search: 'arroz');
    await notifier.setStockFilter(InventoryStockFilter.agotado);
    await notifier.loadNextPage();
    expect(repo.calls[1]['limiteStock'], 'STOCK_AGOTADO');
    expect(repo.calls.last['limiteStock'], 'STOCK_AGOTADO');
    expect(repo.calls.last['clave'], 'arroz');
    expect(repo.calls.last['pageNumber'], 1);
    expect(notifier.state.items.length, 2);
    expect(notifier.state.totalElements, 2);
    await notifier.setStockFilter(InventoryStockFilter.bajo);
    expect(repo.calls.last['limiteStock'], 'STOCK_MINIMO');
    expect(repo.calls.last['conStock'], true);
    expect(repo.calls.last['pageNumber'], 0);
    await notifier.setStockFilter(InventoryStockFilter.todos);
    expect(repo.calls.last.containsKey('limiteStock'), false);
  });
  test('un fallo de página puede reintentarse sin saltar registros', () async {
    final repo = _Repository();
    final notifier = InventoryNotifier(inventoryRepository: repo);
    addTearDown(notifier.dispose);
    await notifier.loadInventory(1);
    repo.fail = true;
    await notifier.loadNextPage();
    expect(notifier.state.pageNumber, 0);
    expect(notifier.state.errorMessage, isNotNull);
    repo.fail = false;
    await notifier.loadNextPage();
    expect(repo.calls.last['pageNumber'], 1);
    expect(notifier.state.errorMessage, isNull);
  });
  test('una respuesta antigua no reemplaza un filtro posterior', () async {
    final repo = _Repository();
    final notifier = InventoryNotifier(inventoryRepository: repo);
    addTearDown(notifier.dispose);
    await notifier.loadInventory(1);
    final oldResponse = Completer<InventoryResponse>();
    repo.deferred = oldResponse;
    final oldRequest = notifier.searchInventory('anterior');
    repo.deferred = null;
    await notifier.setStockFilter(InventoryStockFilter.agotado);
    oldResponse.complete(_page(999));
    await oldRequest;
    expect(notifier.state.items.single.id, isNot(999));
    expect(notifier.state.stockFilter, InventoryStockFilter.agotado);
  });
}
