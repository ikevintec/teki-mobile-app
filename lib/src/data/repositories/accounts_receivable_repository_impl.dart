import 'package:teki_app/src/data/datasource/remote_accounts_receivable.dart';
import 'package:teki_app/src/data/models/response/accounts_receivable_total_response.dart';
import 'package:teki_app/src/data/models/teki_model/accountReceivable.dart';
import 'package:teki_app/src/data/models/teki_model/currency.dart';
import 'package:teki_app/src/domain/datasource/accounts_receivable_datasource.dart';
import 'package:teki_app/src/domain/repositories/accounts_receivable_repository.dart';

class AccountsReceivableRepositoryImpl extends AccountsReceivableRepository {
  final AccountsReceivableDatasource datasource;

  AccountsReceivableRepositoryImpl({AccountsReceivableDatasource? datasource})
      : datasource = datasource ?? RemoteAccountsReceivable();

  @override
  Future<List<AccountsReceivable>> getAccounts(Map<String, dynamic> params) {
    return datasource.getAccounts(params);
  }

  @override
  Future<List<AccountsReceivableTotalResponse>> getTotales(
    Map<String, dynamic> params,
    List<Currency> currencies,
  ) {
    return datasource.getTotales(params, currencies);
  }
}
