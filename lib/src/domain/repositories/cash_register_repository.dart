import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/response/caja_resumen.dart';
import 'package:teki_app/src/data/models/response/cash_register_response.dart';
import 'package:teki_app/src/data/models/teki_model/caja_metodo_pago_balance.dart';
import 'package:teki_app/src/data/models/teki_model/cash_register_detail.dart';

abstract class CashRegisterRepository {
  Future<List<CashRegisterResponse>> getCashRegister({
    required int idPuntoVenta,
    required int idEstacionVenta,
    required String fecha,
    CancelToken? cancelToken,
  });

  /// Cajas en estado APERTURADA del punto de venta/estación, sin filtrar
  /// por fecha (para detectar cajas abiertas de días anteriores).
  Future<List<CashRegisterResponse>> getOpenCashRegisters({
    required int idPuntoVenta,
    required int idEstacionVenta,
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
  });

  /// Resumen agregado del rango (modo reporte), calculado en el servidor.
  Future<CajaResumen> getResumen({
    required String desde,
    required String hasta,
    int? idPuntoVenta,
    int? idEstacionVenta,
  });

  /// Movimientos del rango, paginados (drill-down del modo reporte).
  Future<CashRegisterDetailPage> getMovimientosRango({
    required String desde,
    required String hasta,
    int? idPuntoVenta,
    int? idEstacionVenta,
    String? tipo,
    required int page,
    required int perPage,
    CancelToken? cancelToken,
  });
}
