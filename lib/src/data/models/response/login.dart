import 'package:teki_app/src/data/models/teki_model/user.dart';

class LoginResponse {
  final String? accessToken;
  final String? tokenType;
  final User? user;
  final List<String>? roles;

  LoginResponse({
    this.accessToken,
    this.tokenType,
    this.user,
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

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'tokenType': tokenType,
      'user': user?.toJson(),
      'roles': roles,
    };
  }
}