import 'package:teki_app/src/data/models/response/login.dart';

abstract class AuthRepository {
  Future<LoginResponse> login(String username, String password);
}
