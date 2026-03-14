import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/teki_model/monthlySales.dart';
import 'package:teki_app/src/domain/datasource/monthlySales_datasource.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';

class RemoteMonthlySalesDatasource extends MonthlySalesRepositoryDatasource {
  final Dio dio = ApiClient.dio;

  @override
  Future<List<MonthlySales>> getSales(int idPuntoVenta) async {
    try {
      final response = await dio.get('/sales-months', queryParameters: {
        'idPuntoVenta': idPuntoVenta,
      });

      return (response.data as List)
          .map((json) => MonthlySales.fromJson(json))
          .toList();
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      final resData = e.response?.data;
      final message = (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ?? e.message ?? 'Error de conexión';
      return Future.error(message);
    } catch (e) {
      return Future.error(e.toString());
    }
  }
}
