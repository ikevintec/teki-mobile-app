import 'package:dio/dio.dart';
import 'package:teki_app/src/data/datasource/remote_cash_register.dart';
import 'package:teki_app/src/data/models/response/cash_register_response.dart';
import 'package:teki_app/src/domain/datasource/cash_register_datasource.dart';
import 'package:teki_app/src/domain/repositories/cash_register_repository.dart';

class CashRegisterRepositoryImpl extends CashRegisterRepository {
  final CashRegisterDatasource datasource;

  CashRegisterRepositoryImpl({CashRegisterDatasource? datasource})
      : datasource = datasource ?? RemoteCashRegister();

  @override
  Future<List<CashRegisterResponse>> getCashRegister({
    required int idPuntoVenta,
    required int idEstacionVenta,
    required String fecha,
    CancelToken? cancelToken,
  }) {
    return datasource.getCashRegister(
      idPuntoVenta: idPuntoVenta,
      idEstacionVenta: idEstacionVenta,
      fecha: fecha,
      cancelToken: cancelToken,
    );
  }
}
