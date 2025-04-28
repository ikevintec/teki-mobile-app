
import 'package:teki_app/src/data/datasource/remote_login.dart';
import 'package:teki_app/src/data/models/response/login.dart';
import 'package:teki_app/src/domain/datasource/auth_datasource.dart';
import 'package:teki_app/src/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl extends AuthRepository {
  final AuthDatasource authDatasource;
  AuthRepositoryImpl(
    {AuthDatasource? authDatasource}
  ): authDatasource = authDatasource ?? AuthRemoteDataSource(); 
  @override
  Future<LoginResponse> login(String email, String password) async {
    LoginResponse response = await authDatasource.login(email, password);
    // Return a dummy user for demonstration purposes
    return response;
  }

}