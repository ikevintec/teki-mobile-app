import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/teki_model/config.dart';
import 'package:teki_app/src/domain/datasource/config_datasource.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import 'package:teki_app/src/utils/notifications.dart';

class RemoteConfigDatasource extends ConfigDatasource {
  Dio dio = ApiClient.dio;
  @override
  Future<ConfigCompany> getConfigValue() async {
    try {
      final reponse = await dio.get('/companies/config');
      ConfigCompany config = ConfigCompany.fromJson(reponse.data);
      return config;
    } on DioException catch (e) {
      if (e.response != null) {
        errorNotification(e.response?.data['message']);
      } else {
        errorNotification(e.message ?? 'Error de conexión');
      }
      return Future.error(e.message ?? 'Error de conexión');
    } on Exception catch (e) {
      errorNotification(e.toString());
      return Future.error(e.toString());
    }
  }
}
