import 'package:teki_app/src/data/models/response/accounts_receivable_total_response.dart';
import 'package:teki_app/src/data/models/teki_model/account_receivable.dart';
import 'package:teki_app/src/data/models/teki_model/account_receivable_detail.dart';
import 'package:teki_app/src/data/models/teki_model/currency.dart';

abstract class AccountsReceivableRepository {
  Future<List<AccountsReceivable>> getAccounts(Map<String, dynamic> params);

  Future<List<AccountsReceivableTotalResponse>> getTotales(
    Map<String, dynamic> params,
    List<Currency> currencies,
  );

  Future<AccountsReceivable> getById(int id);

  Future<List<AccountsReceivableDetail>> getDetails(int id);

  Future<void> cancel(int id);

  Future<void> extend(int id, int dias);

  Future<void> registerPayment({
    required AccountsReceivable account,
    required String descripcion,
    String? detalle,
    required double monto,
    required String moneda,
    required List<Map<String, dynamic>> pagos,
    required int idPuntoVenta,
    required int idEstacionVenta,
  });
}
