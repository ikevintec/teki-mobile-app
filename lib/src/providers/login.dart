import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/data/models/response/login.dart';
import 'package:teki_app/src/data/models/user.dart';
import 'package:teki_app/src/data/repositories/auth_repository.impl.dart';
import 'package:teki_app/src/domain/repositories/auth_repository.dart';
import 'package:teki_app/src/shared/services/key_values_storage_impl.dart';
import 'package:teki_app/src/utils/contstants.dart';

//Creacion del Provider que gestionara los cambios de estado
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final AuthRepository authRepository = AuthRepositoryImpl();
  final KeyValueStorageServiceImpl keyvalueStorage =
      KeyValueStorageServiceImpl();
  //final KeyValueStorageServiceImpl keyvalueStorage = KeyValueStorageServiceImpl();
  return AuthStateNotifier(
    authRepository: authRepository,
    keyvalueStorage: keyvalueStorage,
  );
});

//Creacion del notifier que se encargara de manejar el estado de la autenticacion
class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthRepository authRepository;
  final KeyValueStorageServiceImpl keyvalueStorage;
  AuthStateNotifier(
      {required this.authRepository, required this.keyvalueStorage})
      : super(AuthState(isLoggedIn: false));

  void login(String username, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      LoginResponse response = await authRepository.login(username, password);
      state = state.copyWith(
        isLoggedIn: true,
        token: response.accessToken,
        user: response.user,
      );
      await keyvalueStorage.setKeyValue('access_token', response.accessToken);
      await keyvalueStorage.setKeyValue(
          'user', jsonEncode(response.user.toJson()));
      Get.snackbar(
        "Bienvenido",
        "Has iniciado sesión correctamente",
        colorText: Colors.white,
        backgroundColor: ColorSchema.primaryColor,
        duration: const Duration(seconds: 2),
      );
      Get.offAllNamed('/dashboard');
    } on DioException catch (e) {
      String message = 'Ocurrió un error desconocido.';

      if (e.type == DioExceptionType.connectionTimeout) {
        message = 'Tiempo de espera agotado al conectar con el servidor.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        message = 'Tiempo de espera agotado al recibir respuesta del servidor.';
      } else if (e.type == DioExceptionType.sendTimeout) {
        message = 'Tiempo de espera agotado al enviar datos al servidor.';
      } else if (e.type == DioExceptionType.badResponse) {
        final statusCode = e.response?.statusCode;
        final errorData = e.response?.data;
        if (statusCode == 401) {
          message =
              'Credenciales incorrectas. Verifica tu usuario y contraseña.';
        } else if (statusCode == 403) {
          message = 'Acceso denegado. No tienes permisos suficientes.';
        } else if (statusCode == 500) {
          message = 'Error interno del servidor.';
        } else if (errorData is Map && errorData.containsKey('message')) {
          message = errorData['message'];
        } else {
          message = 'Error HTTP $statusCode';
        }
      } else if (e.type == DioExceptionType.unknown) {
        message = 'Error de red o el servidor no está disponible.';
      } else {
        message = e.message ?? 'Error inesperado';
      }

      setError(message);
      Get.snackbar(
        "Error",
        message,
        colorText: Colors.white,
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      );
    } on Exception catch (e) {
      setError('Error inesperado: ${e.toString()}');
      Get.snackbar(
        "Error",
        e.toString(),
        colorText: Colors.white,
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> checkAuthStatus() async {
    final token = await keyvalueStorage.getValue<String>('access_token');
    final userJson = await keyvalueStorage.getValue<String>('user');
    if (token != null && userJson != null) {
      final user = User.fromJson(jsonDecode(userJson));
      state = state.copyWith(
        isLoggedIn: true,
        token: token,
        user: user,
        isLoading: false,
      );
    } else {
      logout();
    }
  }

  void logout() async {
    await keyvalueStorage.removeKey('access_token');
    state = state.copyWith(
      isLoggedIn: false,
      token: null,
      user: null,
      errorMessage: null,
      isLoading: false,
    );
    String actualRoute = Get.currentRoute;
    if (actualRoute != '/login' && actualRoute != '/splashScreen') {
      Get.offAllNamed('/login');
    }
  }

  void setError(String errorMessage) {
    state = state.copyWith(errorMessage: errorMessage);
  }
}

// creacion del estado que se mantendra en el provider
class AuthState {
  final bool isLoggedIn;
  final String? token;
  final String? errorMessage;
  final User? user;
  final bool isLoading;

  AuthState({
    required this.isLoggedIn,
    this.token,
    this.errorMessage,
    this.user,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? token,
    String? errorMessage,
    User? user,
    bool? isLoading,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      token: token ?? this.token,
      errorMessage: errorMessage ?? this.errorMessage,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
