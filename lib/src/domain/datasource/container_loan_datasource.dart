import 'package:teki_app/src/data/models/teki_model/container_loan.dart';

abstract class ContainerLoanDatasource {
  /// Página de préstamos y el total de registros filtrados.
  Future<(List<ContainerLoan>, int)> getLoans({
    int? customerId,
    int? officeId,
    required bool pending,
    required int page,
    required int size,
  });
  Future<List<ContainerLoanTotal>> getTotals({int? customerId, int? officeId});
  Future<List<ContainerReturn>> getReturns(int loanId);
  Future<ContainerLoan> receive(int loanId, ContainerReturn request);
  Future<ContainerLoan> reverse(int loanId, int returnId);
  Future<List<ContainerOpeningProduct>> getOpeningProducts(String term);
  Future<ContainerLoan> registerOpening(ContainerOpening request);
  Future<ContainerLoan> cancelOpening(int loanId);
}
