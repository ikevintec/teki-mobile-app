import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/company.dart';
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
      String errorMessage = 'Error de conexión';
      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? 'Error de conexión';
      } else {
        errorMessage = e.message ?? 'Error de conexión';
      }
      return Future.error(errorMessage);
    } catch (e) {
      return Future.error(e.toString());
    }

  }

}