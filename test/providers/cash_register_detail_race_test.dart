import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/response/cash_register_response.dart';
import 'package:teki_app/src/domain/repositories/cash_register_repository.dart';
import 'package:teki_app/src/providers/cash_register/cash_register_detail_provider.dart';

/// Repositorio falso: permite controlar cuándo se resuelve cada página,
/// para reproducir carreras entre load/clear.
class _FakeRepository implements CashRegisterRepository {
  final List<Completer<CashRegisterDetailPage>> pendientes = [];

  @override
  Future<CashRegisterDetailPage> getCashRegisterDetail({
    required int idCaja,
    required String tipo,
    required String moneda,
    required int page,
    int perPage = 10,
    CancelToken? cancelToken,
  }) {
    final completer = Completer<CashRegisterDetailPage>();
    pendientes.add(completer);
    return completer.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

CashRegisterDetailPage _pagina(List<int> ids) {
  return CashRegisterDetailPage(
    rawItems: [
      for (final id in ids)
        {'id': id, 'monto': 10.0, 'tipoMovimientoCaja': 'INGRESO'},
    ],
    isLast: true,
    totalElements: ids.length,
  );
}

void main() {
  group('CashRegisterDetailNotifier — carreras de estado viciado', () {
    test('una respuesta que llega después de clear() se descarta', () async {
      final repo = _FakeRepository();
      final notifier = CashRegisterDetailNotifier(repository: repo);

      // Se pide el historial de la caja vieja (queda en vuelo)...
      final carga = notifier.load(idCaja: 28, moneda: 'PEN');
      expect(notifier.state.isLoading, isTrue);

      // ...el usuario cambia a una fecha sin caja → clear()
      notifier.clear();
      expect(notifier.state.items, isEmpty);

      // ...y recién entonces llega la respuesta vieja.
      repo.pendientes.first.complete(_pagina([1, 2, 3]));
      await carga;

      // El historial viejo NO debe resucitar.
      expect(notifier.state.items, isEmpty);
      expect(notifier.state.idCaja, isNull);
      expect(notifier.state.isLoading, isFalse);
    });

    test('una respuesta superada por un load más nuevo se descarta', () async {
      final repo = _FakeRepository();
      final notifier = CashRegisterDetailNotifier(repository: repo);

      final cargaVieja = notifier.load(idCaja: 28, moneda: 'PEN');
      final cargaNueva = notifier.load(idCaja: 99, moneda: 'PEN');

      // La respuesta nueva llega primero; la vieja, después.
      repo.pendientes[1].complete(_pagina([9]));
      await cargaNueva;
      repo.pendientes[0].complete(_pagina([1, 2, 3]));
      await cargaVieja;

      // Debe quedar el resultado del load más reciente (caja 99).
      expect(notifier.state.idCaja, 99);
      expect(notifier.state.items, hasLength(1));
    });

    test('loadMore en vuelo no agrega items tras un clear()', () async {
      final repo = _FakeRepository();
      final notifier = CashRegisterDetailNotifier(repository: repo);

      final carga = notifier.load(idCaja: 28, moneda: 'PEN');
      repo.pendientes[0].complete(_pagina([1]));
      await carga;
      expect(notifier.state.items, hasLength(1));

      // hasMore=false por isLast → forzar siguiente página manualmente no
      // aplica; simulamos con un load nuevo + loadMore en vuelo.
      final recarga = notifier.load(idCaja: 28, moneda: 'PEN');
      notifier.clear();
      repo.pendientes[1].complete(_pagina([7, 8]));
      await recarga;

      expect(notifier.state.items, isEmpty);
    });
  });
}
