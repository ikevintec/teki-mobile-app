import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/replicador/replicador_app.dart';
import 'package:teki_app/src/data/models/yape/pago_yape.dart';
import 'package:teki_app/src/domain/datasource/pago_yape_datasource.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';

class RemotePagoYape extends PagoYapeDatasource {
  final Dio dio;

  RemotePagoYape({Dio? dio}) : dio = dio ?? ApiClient.dio;

  @override
  Future<PagoYapePage> getPagos({
    required int pageNumber,
    int perPage = 20,
  }) async {
    try {
      final response = await dio.get(
        '/pagos-yape',
        queryParameters: {
          'pagination': true,
          'pageNumber': pageNumber,
          'perPage': perPage,
          'sortField': 'fechaRegistro',
          'sortOrder': 0,
        },
      );
      return PagoYapePage.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      if (e.response == null) {
        throw Exception('Sin conexión a internet');
      }
      final data = e.response?.data;
      final message = data is Map ? data['mensaje'] ?? data['message'] : null;
      throw Exception(
        message ?? e.message ?? 'No se pudieron cargar los Yapes',
      );
    }
  }

  @override
  Future<PagoYape> createPago({
    required String nombrePagador,
    required double monto,
    required String codigoOperacion,
    required NotificationAppType tipoApp,
  }) async {
    try {
      final response = await dio.post(
        '/pagos-yape',
        data: {
          'nombrePagador': nombrePagador,
          'monto': monto,
          'codigoOperacion': codigoOperacion,
          'tipoApp': tipoApp.code,
        },
      );
      final data = response.data;
      if (data is Map) {
        return PagoYape.fromJson(Map<String, dynamic>.from(data));
      }
      return PagoYape(
        nombrePagador: nombrePagador,
        monto: monto,
        codigoOperacion: codigoOperacion,
        tipoApp: tipoApp,
      );
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      if (e.response == null) {
        throw Exception('Sin conexión a internet');
      }
      final data = e.response?.data;
      final message = data is Map ? data['mensaje'] ?? data['message'] : null;
      throw Exception(
        message ?? e.message ?? 'No se pudo registrar el Yape',
      );
    }
  }
}
