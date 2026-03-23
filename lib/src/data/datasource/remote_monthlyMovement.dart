import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/teki_model/monthlyMovement.dart';
import 'package:teki_app/src/domain/datasource/monthlyMovement_datasource.dart';
//import 'package:teki_app/src/domain/repositories/movement_month_repository.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';

class RemoteMovementMonth extends MovementMonthRepositoryDatasource {
  final Dio dio = ApiClient.dio;

  @override
  Future<List<MonthlyMovement>> getMovementsBySalePoint(
      int idPuntoVenta) async {
    try {
      final response = await dio.get('/movements-months', queryParameters: {
        'idPuntoVenta': idPuntoVenta,
      });

      List<MonthlyMovement> movements = [];
      for (var item in response.data) {
        movements.add(MonthlyMovement.fromJson(item));
      }
      return movements;
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      final resData = e.response?.data;
      final responseMessage = (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ?? e.message ?? 'Error de conexión';
      return Future.error(responseMessage);
    } catch (e) {
      return Future.error(e.toString());
    }
  }
}
