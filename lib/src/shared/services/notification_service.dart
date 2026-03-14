import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teki_app/src/utils/api_client.constant.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _tokenKey = 'fcm_token';
  static const _channelId = 'teki_high_importance';
  static const _channelName = 'Teki Notificaciones';

  // ---------------------------------------------------------------------------
  // Punto de entrada principal — llamar después del login exitoso
  // ---------------------------------------------------------------------------

  Future<void> initialize(int userId) async {
    final granted = await _requestPermission();
    if (!granted) return;

    await _initLocalNotifications();
    await _getAndSaveToken(userId);
    _setupTokenRefresh(userId);
    _setupForegroundHandler();
    _setupBackgroundTapHandler();
    await _setupTerminatedTapHandler();
  }

  // ---------------------------------------------------------------------------
  // Permisos
  // ---------------------------------------------------------------------------

  /// Retorna true si se obtuvo permiso (o si ya estaba concedido).
  Future<bool> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final status = settings.authorizationStatus;
    debugPrint('[FCM] Permiso: $status');
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  // ---------------------------------------------------------------------------
  // flutter_local_notifications
  // ---------------------------------------------------------------------------

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      // El permiso ya lo pidió FirebaseMessaging; no re-pedirlo aquí.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) {
          handleNotificationTap(_decodePayload(payload));
        }
      },
    );

    // Canal de alta importancia — obligatorio en Android 8+
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        importance: Importance.high,
        playSound: true,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  // ---------------------------------------------------------------------------
  // Token FCM
  // ---------------------------------------------------------------------------

  Future<void> _getAndSaveToken(int userId) async {
    try {
      // En iOS el token APNs debe estar disponible antes de pedir el FCM token.
      // Si aún no llegó, esperamos hasta 10 s antes de continuar.
      if (Platform.isIOS) {
        String? apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          for (int i = 0; i < 10; i++) {
            await Future.delayed(const Duration(seconds: 1));
            apnsToken = await _messaging.getAPNSToken();
            if (apnsToken != null) break;
          }
        }
        if (apnsToken == null) {
          debugPrint('[FCM] APNs token no disponible, se omite registro');
          return;
        }
      }

      final token = await _messaging.getToken();
      if (token == null) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);

      await _registerTokenWithBackend(token, userId);
    } catch (e) {
      debugPrint('[FCM] Error obteniendo token: $e');
    }
  }

  Future<void> _registerTokenWithBackend(String token, int userId) async {
    final body = {
      'token': token,
      'userId': userId,
      'platform': Platform.isAndroid ? 'android' : 'ios',
    };

    try {
      await ApiClient.dio.post('/notifications/register-token', data: body);
      debugPrint('[FCM] Token registrado en el backend');
    } catch (e) {
      debugPrint('[FCM] Registro fallido, reintentando en 3 s... ($e)');
      Future.delayed(const Duration(seconds: 3), () async {
        try {
          await ApiClient.dio
              .post('/notifications/register-token', data: body);
          debugPrint('[FCM] Token registrado en el reintento');
        } catch (retryError) {
          debugPrint('[FCM] Reintento fallido: $retryError');
          // El token ya está guardado localmente; se puede reenviar
          // en el próximo ciclo de vida de la app.
        }
      });
    }
  }

  void _setupTokenRefresh(int userId) {
    _messaging.onTokenRefresh.listen((newToken) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, newToken);
      await _registerTokenWithBackend(newToken, userId);
    });
  }

  // ---------------------------------------------------------------------------
  // Handlers de mensajes
  // ---------------------------------------------------------------------------

  /// Foreground: FCM no muestra la notificación automáticamente → usar local.
  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      _showLocalNotification(
        id: message.hashCode,
        title: notification.title ?? 'Teki',
        body: notification.body ?? '',
        data: message.data,
      );
    });
  }

  /// Background tap: el usuario toca la notificación estando la app en segundo plano.
  void _setupBackgroundTapHandler() {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleNotificationTap(message.data);
    });
  }

  /// Terminated tap: el usuario toca la notificación y la app estaba cerrada.
  Future<void> _setupTerminatedTapHandler() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) {
      // Pequeño delay para que el árbol de widgets esté listo antes de navegar.
      Future.delayed(const Duration(milliseconds: 800), () {
        handleNotificationTap(message.data);
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Notificación local (foreground)
  // ---------------------------------------------------------------------------

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: _encodePayload(data),
    );
  }

  // ---------------------------------------------------------------------------
  // Navegación
  // ---------------------------------------------------------------------------

  /// Despacha la navegación según el campo "type" del data payload.
  ///
  /// Ejemplo de payload del backend:
  ///   { "type": "dish_ready", "dishId": "123" }
  void handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    debugPrint('[FCM] Navegando por tipo: $type');

    switch (type) {
      case 'dish_ready':
        Get.toNamed('/restaurant/comanda', arguments: data);
      case 'order_new':
        Get.toNamed('/restaurant/mesas', arguments: data);
      case 'sale_update':
        Get.toNamed('/sales', arguments: data);
      default:
        Get.toNamed('/dashboard');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers de payload
  // ---------------------------------------------------------------------------

  String _encodePayload(Map<String, dynamic> data) => jsonEncode(data);

  Map<String, dynamic> _decodePayload(String payload) {
    try {
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
