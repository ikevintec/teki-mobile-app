import 'package:teki_app/src/data/datasource/remote_accounts_receivable.dart';
import 'package:teki_app/src/data/models/response/accounts_receivable_total_response.dart';
import 'package:teki_app/src/data/models/teki_model/account_receivable.dart';
import 'package:teki_app/src/data/models/teki_model/account_receivable_detail.dart';
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

  @override
  Future<AccountsReceivable> getById(int id) {
    return datasource.getById(id);
  }

  @override
  Future<List<AccountsReceivableDetail>> getDetails(int id) {
    return datasource.getDetails(id);
  }

  @override
  Future<void> cancel(int id) {
    return datasource.cancel(id);
  }

  @override
  Future<void> extend(int id, int dias) {
    return datasource.extend(id, dias);
  }

  @override
  Future<void> registerPayment({
    required AccountsReceivable account,
    required String descripcion,
    String? detalle,
    required double monto,
    required String moneda,
    required List<Map<String, dynamic>> pagos,
    required int idPuntoVenta,
    required int idEstacionVenta,
  }) {
    return datasource.registerPayment(
      account: account,
      descripcion: descripcion,
      detalle: detalle,
      monto: monto,
      moneda: moneda,
      pagos: pagos,
      idPuntoVenta: idPuntoVenta,
      idEstacionVenta: idEstacionVenta,
    );
  }
}
