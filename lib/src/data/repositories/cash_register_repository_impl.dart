import 'package:dio/dio.dart';
import 'package:teki_app/src/data/datasource/remote_cash_register.dart';
import 'package:teki_app/src/data/models/response/cash_register_response.dart';
import 'package:teki_app/src/data/models/teki_model/caja_metodo_pago_balance.dart';
import 'package:teki_app/src/data/models/teki_model/cash_register_detail.dart';
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

  @override
  Future<List<CashRegisterResponse>> getOpenCashRegisters({
    required int idPuntoVenta,
    required int idEstacionVenta,
  }) {
    return datasource.getOpenCashRegisters(
      idPuntoVenta: idPuntoVenta,
      idEstacionVenta: idEstacionVenta,
    );
  }

  @override
  Future<CashRegisterDetailPage> getCashRegisterDetail({
    required int idCaja,
    required String tipo,
    required String moneda,
    required int page,
    int perPage = 10,
    CancelToken? cancelToken,
  }) {
    return datasource.getCashRegisterDetail(
      idCaja: idCaja,
      tipo: tipo,
      moneda: moneda,
      page: page,
      perPage: perPage,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<CajaMetodoPagoBalance>> getTotalesMetodoPago({
    required int idCaja,
    CancelToken? cancelToken,
  }) {
    return datasource.getTotalesMetodoPago(
      idCaja: idCaja,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<CashRegisterDetail> createCashMovement({
    required int idCaja,
    required String tipoMovimiento,
    required String concepto,
    required String moneda,
    required double monto,
    required String descripcion,
    String? detalle,
    required int turno,
    required List<Map<String, dynamic>> pagos,
    CancelToken? cancelToken,
  }) {
    return datasource.createCashMovement(
      idCaja: idCaja,
      tipoMovimiento: tipoMovimiento,
      concepto: concepto,
      moneda: moneda,
      monto: monto,
      descripcion: descripcion,
      detalle: detalle,
      turno: turno,
      pagos: pagos,
      cancelToken: cancelToken,
    );
  }
}
