import 'package:dio/dio.dart';
import 'package:get/route_manager.dart';
import 'package:teki_app/src/data/models/saleStation.dart';
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
      if (e.response != null) {
        Get.snackbar('Error', e.response?.data['message']);
      } else {
        Get.snackbar('Error', e.message ?? 'Error de conexión');
      }
      return [];
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return [];
    }
  }
}
