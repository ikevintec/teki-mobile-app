import 'package:teki_app/src/data/models/response/accounts_receivable_total_response.dart';
import 'package:teki_app/src/data/models/teki_model/accountReceivable.dart';
import 'package:teki_app/src/data/models/teki_model/currency.dart';

abstract class AccountsReceivableDatasource {
  /// Consulta paginada de cuentas por cobrar/pagar (depende de `tipoCuenta` en params)
  Future<List<AccountsReceivable>> getAccounts(Map<String, dynamic> params);

  /// Hace una consulta de totales por cada moneda recibida, reutilizando los mismos filtros
  Future<List<AccountsReceivableTotalResponse>> getTotales(
    Map<String, dynamic> params,
    List<Currency> currencies,
  );
}
