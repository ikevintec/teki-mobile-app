// auth_middleware.dart
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/providers/login.dart';
import 'package:teki_app/main.dart'; // Para usar globalContainer

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authState = globalContainer.read(authStateProvider);
    final isLoggedIn = authState.isLoggedIn;
    print(isLoggedIn);



    if (isLoggedIn && (route == '/login' || route == '/splashScreen')) {
      return const RouteSettings(name: '/dashboard');
    }

    return null;
  }
}
