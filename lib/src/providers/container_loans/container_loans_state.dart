import 'package:teki_app/src/data/models/teki_model/container_loan.dart';
import 'package:teki_app/src/data/models/teki_model/customer.dart';

class ContainerLoansState {
  final List<ContainerLoan> items;
  final List<ContainerLoanTotal> totals;
  final Customer? customer;
  final int? officeId;
  final bool pending;
  final int page;
  final int totalRecords;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const ContainerLoansState({
    this.items = const [],
    this.totals = const [],
    this.customer,
    this.officeId,
    this.pending = true,
    this.page = 0,
    this.totalRecords = 0,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  bool get last => items.length >= totalRecords;

  static const _keep = Object();

  ContainerLoansState copyWith({
    List<ContainerLoan>? items,
    List<ContainerLoanTotal>? totals,
    Object? customer = _keep,
    Object? officeId = _keep,
    bool? pending,
    int? page,
    int? totalRecords,
    bool? isLoading,
    bool? isSaving,
    Object? errorMessage = _keep,
  }) {
    return ContainerLoansState(
      items: items ?? this.items,
      totals: totals ?? this.totals,
      customer: customer == _keep ? this.customer : customer as Customer?,
      officeId: officeId == _keep ? this.officeId : officeId as int?,
      pending: pending ?? this.pending,
      page: page ?? this.page,
      totalRecords: totalRecords ?? this.totalRecords,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage == _keep
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
