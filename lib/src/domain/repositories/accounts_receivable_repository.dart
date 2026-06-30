import 'package:teki_app/src/data/models/response/accounts_receivable_total_response.dart';
import 'package:teki_app/src/data/models/teki_model/accountReceivable.dart';
import 'package:teki_app/src/data/models/teki_model/currency.dart';

abstract class AccountsReceivableRepository {
  Future<List<AccountsReceivable>> getAccounts(Map<String, dynamic> params);

  Future<List<AccountsReceivableTotalResponse>> getTotales(
    Map<String, dynamic> params,
    List<Currency> currencies,
  );
}
