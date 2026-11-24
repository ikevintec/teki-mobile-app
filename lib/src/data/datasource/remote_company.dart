import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/teki_model/company.dart';
import 'package:teki_app/src/domain/datasource/company_datasource.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';

class RemoteCompany extends CompanyDatasource {
  Dio dio = ApiClient.dio;
  @override
  Future<Company> getCompanyById(int id) async{
    try {
      final response = await dio.get('/root/companies/$id');
      return Company.fromJson(response.data);
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

  @override
  Future<Company> getCurrentCompanyLocalProducts() async {
    try {
      final response = await dio.get('/companies/current/local-products-timestamp');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return Company.fromJson(data);
      }
      if (data is Map) {
        return Company.fromJson(Map<String, dynamic>.from(data));
      }
      return Company();
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      final resData = e.response?.data;
      final errorMessage = (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ?? e.message ?? 'Error de conexiÃ³n';
      return Future.error(errorMessage);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  @override
  Future<void> updateLocalTimestamp(String timestamp) async {
    try {
      await dio.patch(
        '/root/companies/localTimestamp',
        data: {'lastUpdateLocalProducts': timestamp},
      );
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      final resData = e.response?.data;
      final errorMessage = (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ?? e.message ?? 'Error de conexiÃ³n';
      return Future.error(errorMessage);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

}
