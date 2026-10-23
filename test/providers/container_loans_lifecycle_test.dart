import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/container_loan.dart';
import 'package:teki_app/src/domain/repositories/container_loan_repository.dart';
import 'package:teki_app/src/providers/container_loans/container_loans_provider.dart';

class _Repository implements ContainerLoanRepository {
  final requests = <Completer<(List<ContainerLoan>, int)>>[];
  @override
  Future<(List<ContainerLoan>, int)> getLoans({
    int? customerId,
    int? officeId,
    required bool pending,
    required int page,
    required int size,
  }) {
    final request = Completer<(List<ContainerLoan>, int)>();
    requests.add(request);
    return request.future;
  }

  @override
  Future<List<ContainerLoanTotal>> getTotals({
    int? customerId,
    int? officeId,
  }) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final paginar in [false, true]) {
    for (final falla in [false, true]) {
      test(
        'cerrar módulo durante ${paginar ? 'paginación' : 'carga'} con ${falla ? 'error' : 'respuesta'} tardía',
        () async {
          final repo = _Repository();
          final notifier = ContainerLoansNotifier(repository: repo);
          if (paginar) {
            final first = notifier.load();
            repo.requests.last.complete(([const ContainerLoan(id: 1)], 2));
            await first;
          }
          final pending = paginar ? notifier.loadNextPage() : notifier.load();
          notifier.dispose();
          if (falla) {
            repo.requests.last.completeError(Exception('offline'));
          } else {
            repo.requests.last.complete((<ContainerLoan>[], 0));
          }
          await expectLater(pending, completes);
        },
      );
    }
  }
  test(
    'respuesta anterior no sustituye filtros ni resultados más recientes',
    () async {
      final repo = _Repository();
      final notifier = ContainerLoansNotifier(repository: repo);
      addTearDown(notifier.dispose);
      final old = notifier.load(officeId: 1);
      final current = notifier.load(officeId: 2);
      repo.requests.last.complete(([const ContainerLoan(id: 2)], 1));
      await current;
      repo.requests.first.complete(([const ContainerLoan(id: 1)], 1));
      await old;
      expect(notifier.state.officeId, 2);
      expect(notifier.state.items.single.id, 2);
    },
  );
}
