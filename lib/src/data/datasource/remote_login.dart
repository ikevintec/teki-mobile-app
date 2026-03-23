import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/response/login.dart';
import 'package:teki_app/src/domain/datasource/auth_datasource.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';

class AuthRemoteDataSource extends AuthDatasource {
  Dio dio = ApiClient.dio;

  @override
  Future<LoginResponse> login(String username, String password) async {
      final response = await dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      return LoginResponse.fromJson(response.data);
  }
}
