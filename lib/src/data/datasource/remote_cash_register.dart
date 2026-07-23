import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/response/caja_resumen.dart';
import 'package:teki_app/src/data/models/response/cash_register_response.dart';
import 'package:teki_app/src/data/models/teki_model/caja_metodo_pago_balance.dart';
import 'package:teki_app/src/data/models/teki_model/cash_register_detail.dart';
import 'package:teki_app/src/domain/datasource/cash_register_datasource.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import 'package:teki_app/src/utils/notifications.dart';

class RemoteCashRegister extends CashRegisterDatasource {
  final Dio dio = ApiClient.dio;

  @override
  Future<List<CashRegisterResponse>> getCashRegister({
    required int idPuntoVenta,
    required int idEstacionVenta,
    required String fecha,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.get(
        '/cash-register',
        queryParameters: {
          'paginacion': false,
          'fecha': fecha,
          'idPuntoVenta': idPuntoVenta,
          'idEstacionVenta': idEstacionVenta,
        },
        cancelToken: cancelToken,
      );
      final data = response.data as List;
      return data
          .map((e) => CashRegisterResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) rethrow;
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      if (e.response == null) {
        return Future.error('Sin conexión a internet');
      }
      final resData = e.response?.data;
      final msg = (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ?? e.message ?? 'Error de conexión';
      errorNotification(msg);
      return Future.error(msg);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  @override
  Future<List<CashRegisterResponse>> getOpenCashRegisters({
    required int idPuntoVenta,
    required int idEstacionVenta,
  }) async {
    try {
      final response = await dio.get(
        '/cash-register',
        queryParameters: {
          'paginacion': false,
          'estadoCaja': 'APERTURADA',
          'idPuntoVenta': idPuntoVenta,
          'idEstacionVenta': idEstacionVenta,
        },
      );
      final data = response.data as List;
      return data
          .map((e) => CashRegisterResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Consulta auxiliar (banner de caja abierta): un fallo aquí no debe
      // interrumpir la carga principal de la caja.
      return [];
    }
  }

  @override
  Future<CashRegisterDetailPage> getCashRegisterDetail({
    required int idCaja,
    required String tipo,
    required String moneda,
    required int page,
    int perPage = 10,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.get(
        '/cash-register-detail',
        queryParameters: {
          'idCaja': idCaja,
          'tipo': tipo,
          'moneda': moneda,
          'perPage': perPage,
          'pageNumber': page,
        },
        cancelToken: cancelToken,
      );
      return CashRegisterDetailPage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) rethrow;
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      if (e.response == null) {
        return Future.error('Sin conexión a internet');
      }
      final resData = e.response?.data;
      final msg = (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ?? e.message ?? 'Error de conexión';
      errorNotification(msg);
      return Future.error(msg);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  @override
  Future<List<CajaMetodoPagoBalance>> getTotalesMetodoPago({
    required int idCaja,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.get(
        '/cash-register-detail/operations/totales-metodo-pago',
        queryParameters: {'idCaja': idCaja},
        cancelToken: cancelToken,
      );
      final data = response.data as List;
      return data.map((e) => CajaMetodoPagoBalance.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) rethrow;
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      if (e.response == null) {
        return Future.error('Sin conexión a internet');
      }
      final resData = e.response?.data;
      final msg = (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ?? e.message ?? 'Error de conexión';
      errorNotification(msg);
      return Future.error(msg);
    } catch (e) {
      return Future.error(e.toString());
    }
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
  }) async {
    try {
      final body = {
        'id': null,
        'tipoMovimientoCaja': tipoMovimiento,
        'conceptoMovimientoCaja': concepto,
        'monedaMovimientoCaja': moneda,
        'pagos': pagos,
        'monto': monto,
        'turno': turno,
        'descripcion': descripcion,
        'detalle': detalle,
        'cashRegister': {'id': idCaja},
        'fechaMovimiento': DateTime.now().toUtc().toIso8601String(),
      };
      final response = await dio.post(
        '/cash-register-detail',
        data: body,
        cancelToken: cancelToken,
      );
      return CashRegisterDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) rethrow;
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      if (e.response == null) {
        return Future.error('Sin conexión a internet');
      }
      final resData = e.response?.data;
      final msg = (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ?? e.message ?? 'Error de conexión';
      errorNotification(msg);
      return Future.error(msg);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  @override
  Future<CajaResumen> getResumen({
    required String desde,
    required String hasta,
    int? idPuntoVenta,
    int? idEstacionVenta,
  }) async {
    try {
      final response = await dio.get(
        '/cash-register-detail/operations/resumen',
        queryParameters: {
          'filtroDesde': desde,
          'filtroHasta': hasta,
          if (idPuntoVenta != null) 'idPuntoVenta': idPuntoVenta,
          if (idEstacionVenta != null) 'idEstacionVenta': idEstacionVenta,
        },
      );
      return CajaResumen.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      if (e.response == null) {
        return Future.error('Sin conexión a internet');
      }
      final resData = e.response?.data;
      final msg = (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ?? e.message ?? 'Error de conexión';
      return Future.error(msg);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  @override
  Future<CashRegisterDetailPage> getMovimientosRango({
    required String desde,
    required String hasta,
    int? idPuntoVenta,
    int? idEstacionVenta,
    String? tipo,
    required int page,
    required int perPage,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.get(
        '/cash-register-detail',
        queryParameters: {
          'filtroDesde': desde,
          'filtroHasta': hasta,
          if (idPuntoVenta != null) 'idPuntoVenta': idPuntoVenta,
          if (idEstacionVenta != null) 'idEstacionVenta': idEstacionVenta,
          if (tipo != null) 'tipo': tipo,
          'perPage': perPage,
          'pageNumber': page,
        },
        cancelToken: cancelToken,
      );
      return CashRegisterDetailPage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) rethrow;
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      if (e.response == null) {
        return Future.error('Sin conexión a internet');
      }
      final resData = e.response?.data;
      final msg = (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ?? e.message ?? 'Error de conexión';
      errorNotification(msg);
      return Future.error(msg);
    } catch (e) {
      return Future.error(e.toString());
    }
  }
}
