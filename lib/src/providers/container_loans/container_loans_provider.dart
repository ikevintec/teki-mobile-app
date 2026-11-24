import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/container_loan.dart';
import 'package:teki_app/src/data/repositories/container_loan_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/container_loan_repository.dart';
import 'package:teki_app/src/providers/container_loans/container_loans_state.dart';
import 'package:uuid/uuid.dart';

final containerLoanRepositoryProvider = Provider<ContainerLoanRepository>(
  (ref) => ContainerLoanRepositoryImpl(),
);

final containerLoansProvider =
    StateNotifierProvider.autoDispose<
      ContainerLoansNotifier,
      ContainerLoansState
    >((ref) {
      return ContainerLoansNotifier(
        repository: ref.watch(containerLoanRepositoryProvider),
      );
    });

class ContainerLoansNotifier extends StateNotifier<ContainerLoansState> {
  final ContainerLoanRepository repository;
  static const pageSize = 20;
  int _requestVersion = 0;

  ContainerLoansNotifier({required this.repository})
    : super(const ContainerLoansState());

  /// Recarga desde la primera página con los filtros actuales (o los nuevos).
  Future<void> load({
    Object? customer = _unchanged,
    Object? officeId = _unchanged,
    bool? pending,
  }) async {
    if (!mounted) return;
    final requestVersion = ++_requestVersion;
    state = state.copyWith(
      customer: customer == _unchanged ? state.customer : customer,
      officeId: officeId == _unchanged ? state.officeId : officeId,
      pending: pending,
      isLoading: true,
      errorMessage: null,
    );
    try {
      final customerId = state.customer?.id;
      final results = await Future.wait([
        repository.getLoans(
          customerId: customerId,
          officeId: state.officeId,
          pending: state.pending,
          page: 0,
          size: pageSize,
        ),
        repository.getTotals(customerId: customerId, officeId: state.officeId),
      ]);
      if (!mounted || requestVersion != _requestVersion) return;
      final (items, total) = results[0] as (List<ContainerLoan>, int);
      state = state.copyWith(
        items: items,
        totalRecords: total,
        totals: results[1] as List<ContainerLoanTotal>,
        page: 0,
        isLoading: false,
      );
    } catch (error) {
      if (!mounted || requestVersion != _requestVersion) return;
      state = state.copyWith(
        items: const [],
        totals: const [],
        totalRecords: 0,
        isLoading: false,
        errorMessage: _message(error),
      );
    }
  }

  Future<void> loadNextPage() async {
    if (!mounted || state.isLoading || state.last) return;
    final requestVersion = ++_requestVersion;
    state = state.copyWith(isLoading: true);
    try {
      final (items, total) = await repository.getLoans(
        customerId: state.customer?.id,
        officeId: state.officeId,
        pending: state.pending,
        page: state.page + 1,
        size: pageSize,
      );
      if (!mounted || requestVersion != _requestVersion) return;
      state = state.copyWith(
        items: [...state.items, ...items],
        totalRecords: total,
        page: state.page + 1,
        isLoading: false,
      );
    } catch (error) {
      if (!mounted || requestVersion != _requestVersion) return;
      state = state.copyWith(isLoading: false, errorMessage: _message(error));
    }
  }

  /// Registra la devolución. Devuelve el préstamo actualizado o lanza el error.
  /// Reintentar con el mismo `requestId` no ingresa stock dos veces.
  Future<ContainerLoan> receive(ContainerLoan loan, ContainerReturn request) =>
      _saving(() => repository.receive(loan.id!, request));

  Future<ContainerLoan> reverse(ContainerLoan loan, ContainerReturn row) =>
      _saving(() => repository.reverse(loan.id!, row.id!));

  Future<ContainerLoan> registerOpening(ContainerOpening request) =>
      _saving(() => repository.registerOpening(request));

  Future<ContainerLoan> cancelOpening(ContainerLoan loan) =>
      _saving(() => repository.cancelOpening(loan.id!));

  Future<List<ContainerOpeningProduct>> openingProducts(String term) =>
      repository.getOpeningProducts(term);

  Future<List<ContainerReturn>> history(ContainerLoan loan) =>
      repository.getReturns(loan.id!);

  static String newRequestId() => const Uuid().v4();

  Future<ContainerLoan> _saving(Future<ContainerLoan> Function() action) async {
    if (state.isSaving) throw Exception('Hay una operación en curso');
    state = state.copyWith(isSaving: true);
    try {
      final result = await action();
      if (mounted) load();
      return result;
    } finally {
      if (mounted) state = state.copyWith(isSaving: false);
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}

const _unchanged = Object();
