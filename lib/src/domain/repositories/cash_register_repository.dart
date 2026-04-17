import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/response/cash_register_response.dart';
import 'package:teki_app/src/data/models/teki_model/caja_metodo_pago_balance.dart';

abstract class CashRegisterRepository {
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

  Future<List<CajaMetodoPagoBalance>> getTotalesMetodoPago({
    required int idCaja,
    CancelToken? cancelToken,
  });
}
