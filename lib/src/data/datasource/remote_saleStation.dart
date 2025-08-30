import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/teki_model/saleStation.dart';
import 'package:teki_app/src/domain/datasource/sale_station.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';

class RemoteSalestation extends SaleStationDataSource {
  Dio dio = ApiClient.dio;
  @override
  Future<List<SaleStation>> getSaleStations(int idPuntoVenta) async {
    try {
      final response = await dio.get('/sale-stations',
          queryParameters: {'idPuntoVenta': idPuntoVenta, 'paginacion': false});
      List<SaleStation> saleStations = [];
      for (var item in response.data) {
        saleStations.add(SaleStation.fromJson(item));
      }
      return saleStations;
    } on DioException catch (e) {
      // Si es un error de sesión expirada, no procesarlo aquí
      if (e.message == 'SESSION_EXPIRED') {
        return Future.error('Sesión expirada');
      }
      
      String responseMessage = 'Error de conexión';
      if (e.response != null) {
        responseMessage = e.response?.data['message'] ?? 'Error de conexión';
      } else {
        responseMessage = e.message ?? 'Error de conexión';
      }
      return Future.error(responseMessage);
    } catch (e) {
      return Future.error(e.toString());
    }
  }
}
