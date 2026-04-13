import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/response/cash_register_response.dart';

abstract class CashRegisterDatasource {
  Future<List<CashRegisterResponse>> getCashRegister({
    required int idPuntoVenta,
    required int idEstacionVenta,
    required String fecha,
    CancelToken? cancelToken,
  });

  Future<CashRegisterDetailPage> getCashRegisterDetail({
    required int idCaja,
    required String tipo,
    required String moneda,
    required int page,
    int perPage,
    CancelToken? cancelToken,
  });
}
