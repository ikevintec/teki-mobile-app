// auth_middleware.dart
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/providers/auth/login.dart';
import 'package:teki_app/main.dart'; // Para usar globalContainer

class AuthMiddleware extends GetMiddleware {
  /// Rutas accesibles sin sesión activa.
  static const Set<String> _publicRoutes = {
    '/splashScreen',
    '/onboarding',
    '/login',
    '/register',
    '/forgotPassword',
  };

  @override
  RouteSettings? redirect(String? route) {
    final authState = globalContainer.read(authStateProvider);
    final isLoggedIn = authState.isLoggedIn;
    final isPublicRoute = route != null && _publicRoutes.contains(route);

    if (isLoggedIn && (route == '/login' || route == '/splashScreen' || route == '/onboarding')) {
      return const RouteSettings(name: '/dashboard');
    }

    if (!isLoggedIn && !isPublicRoute) {
      return const RouteSettings(name: '/login');
    }

    return null;
  }
}
