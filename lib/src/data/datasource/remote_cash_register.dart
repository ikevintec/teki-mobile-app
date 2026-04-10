import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/response/cash_register_response.dart';
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
      final resData = e.response?.data;
      final msg = (resData is Map
              ? (resData['mensaje'] ?? resData['message'])
              : null) ??
          e.message ??
          'Error de conexión';
      errorNotification(msg);
      return Future.error(msg);
    } catch (e) {
      return Future.error(e.toString());
    }
  }
}
