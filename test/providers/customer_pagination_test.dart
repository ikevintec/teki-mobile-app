import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/response/customer.dart';
import 'package:teki_app/src/data/models/teki_model/customer.dart';
import 'package:teki_app/src/domain/repositories/customer_repository.dart';
import 'package:teki_app/src/providers/customers/customers.dart';

class _Customers implements CustomersRepository {
  final requests = <Completer<CustomerResponse>>[];
  @override
  Future<CustomerResponse> getCustomers(Map<String, dynamic> params) {
    final request = Completer<CustomerResponse>();
    requests.add(request);
    return request.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'descarta respuesta anterior tras limpiar estado y recargar en otro ámbito',
    () async {
      final repo = _Customers();
      final container = ProviderContainer(
        overrides: [
          customersProvider.overrideWith(
            (ref) =>
                CustomersStateNotifier(customersRepository: repo, ref: ref),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(customersProvider.notifier);
      final oldRequest = notifier.loadFirstPage();
      notifier.clearState();
      final currentRequest = notifier.loadFirstPage();
      repo.requests[1].complete(
        CustomerResponse(content: [Customer(id: 2)], last: true),
      );
      await currentRequest;
      repo.requests[0].complete(
        CustomerResponse(content: [Customer(id: 1)], last: true),
      );
      await oldRequest;
      expect(container.read(customersProvider).customers!.single.id, 2);
      await notifier.loadMorePages();
      expect(
        repo.requests.length,
        2,
      ); // No consulta otra página tras last=true.
    },
  );
}
