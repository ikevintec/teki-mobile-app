import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/teki_model/currency.dart';
import 'package:teki_app/src/domain/datasource/currency_datasource.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';

class RemoteCurrencies implements CurrencyDatasource {
  Dio dio = ApiClient.dio;
  @override
  Future<List<Currency>> getCurrencies() async {
    try {
      final response = await dio.get('/currencies');
      List<Currency> currencies = (response.data as List)
          .map((currency) => Currency.fromJson(currency))
          .toList();
      return currencies;
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      final resData = e.response?.data;
      final errorMessage = (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ?? e.message ?? 'Error de conexión';
      return Future.error(errorMessage);
    } catch (e) {
      return Future.error(e.toString());
    }
  }
}
