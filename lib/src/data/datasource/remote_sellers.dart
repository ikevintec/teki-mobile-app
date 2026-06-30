import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/teki_model/seller.dart';
import 'package:teki_app/src/domain/datasource/seller_datasource.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';

class RemoteSellers implements SellerDatasource {
  final Dio dio = ApiClient.dio;

  @override
  Future<List<Seller>> getAllSellers() async {
    try {
      final response = await dio.get('/users/all');
      return (response.data as List)
          .map((json) => Seller.fromJson(json))
          .toList();
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      final resData = e.response?.data;
      final errorMessage = (resData is Map
              ? (resData['mensaje'] ?? resData['message'])
              : null) ??
          e.message ??
          'Error de conexión';
      return Future.error(errorMessage);
    } catch (e) {
      return Future.error(e.toString());
    }
  }
}
