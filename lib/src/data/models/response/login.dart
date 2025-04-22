import 'package:teki_app/src/data/models/user.dart';

class LoginResponse {
  final String accessToken;
  final String tokenType;
  final User user;
  final List<String>? roles;

  LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.user,
    this.roles,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'],
      tokenType: json['tokenType'],
      user: User.fromJson(json['user']),
      roles: json['roles'] != null
          ? List<String>.from(json['roles'])
          : null,
    );
  }
}