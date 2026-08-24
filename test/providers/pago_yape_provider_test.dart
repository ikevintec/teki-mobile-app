import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/yape/pago_yape.dart';
import 'package:teki_app/src/domain/repositories/pago_yape_repository.dart';
import 'package:teki_app/src/providers/yape/pago_yape_provider.dart';

class _FakePagoYapeRepository extends PagoYapeRepository {
  final List<int> requestedPages = [];

  @override
  Future<PagoYape> createPago({
    required String nombrePagador,
    required double monto,
    required String codigoOperacion,
  }) async {
    return PagoYape(
      nombrePagador: nombrePagador,
      monto: monto,
      codigoOperacion: codigoOperacion,
    );
  }

  @override
  Future<PagoYapePage> getPagos({
    required int pageNumber,
    int perPage = 20,
  }) async {
    requestedPages.add(pageNumber);
    return PagoYapePage(
      content: [
        PagoYape(
          id: pageNumber + 1,
          nombrePagador: 'Pagador $pageNumber',
          monto: 10 + pageNumber.toDouble(),
          codigoOperacion: 'OP-$pageNumber',
        ),
      ],
      number: pageNumber,
      totalPages: 2,
      totalElements: 2,
      first: pageNumber == 0,
      last: pageNumber == 1,
    );
  }
}

void main() {
  test(
    'carga la primera página y agrega la siguiente al hacer loadMore',
    () async {
      final repository = _FakePagoYapeRepository();
      final notifier = PagoYapeListNotifier(repository);

      await notifier.loadFirstPage();
      expect(notifier.state.pagos, hasLength(1));
      expect(notifier.state.hasMore, isTrue);
      expect(notifier.state.totalElements, 2);

      await notifier.loadMore();
      expect(notifier.state.pagos, hasLength(2));
      expect(notifier.state.page, 1);
      expect(notifier.state.hasMore, isFalse);
      expect(repository.requestedPages, [0, 1]);

      notifier.dispose();
    },
  );
}
