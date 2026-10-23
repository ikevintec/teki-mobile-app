import 'package:teki_app/src/data/datasource/remote_container_loan.dart';
import 'package:teki_app/src/data/models/teki_model/container_loan.dart';
import 'package:teki_app/src/domain/datasource/container_loan_datasource.dart';
import 'package:teki_app/src/domain/repositories/container_loan_repository.dart';

class ContainerLoanRepositoryImpl extends ContainerLoanRepository {
  final ContainerLoanDatasource datasource;

  ContainerLoanRepositoryImpl({ContainerLoanDatasource? datasource})
    : datasource = datasource ?? RemoteContainerLoan();

  @override
  Future<(List<ContainerLoan>, int)> getLoans({
    int? customerId,
    int? officeId,
    required bool pending,
    required int page,
    required int size,
  }) => datasource.getLoans(
    customerId: customerId,
    officeId: officeId,
    pending: pending,
    page: page,
    size: size,
  );

  @override
  Future<List<ContainerLoanTotal>> getTotals({
    int? customerId,
    int? officeId,
  }) => datasource.getTotals(customerId: customerId, officeId: officeId);

  @override
  Future<List<ContainerReturn>> getReturns(int loanId) =>
      datasource.getReturns(loanId);

  @override
  Future<ContainerLoan> receive(int loanId, ContainerReturn request) =>
      datasource.receive(loanId, request);

  @override
  Future<ContainerLoan> reverse(int loanId, int returnId) =>
      datasource.reverse(loanId, returnId);

  @override
  Future<List<ContainerOpeningProduct>> getOpeningProducts(String term) =>
      datasource.getOpeningProducts(term);

  @override
  Future<ContainerLoan> registerOpening(ContainerOpening request) =>
      datasource.registerOpening(request);

  @override
  Future<ContainerLoan> cancelOpening(int loanId) =>
      datasource.cancelOpening(loanId);
}
