import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/orders_restaurant/orders_restaurant_provider.dart';
import 'package:teki_app/src/providers/restaurant/restaurant_provider.dart';
import 'package:teki_app/src/presentation/screens/push_notification_events/dish_desk_ready_screen.dart';
import 'package:teki_app/src/presentation/screens/push_notification_events/order_ready_to_pay_screen.dart';
import 'package:teki_app/main.dart' show globalContainer;

import 'package:teki_app/src/utils/api_client.constant.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _tokenKey = 'fcm_token';
  static const _channelId = 'teki_high_importance';
  static const _channelName = 'Teki Notificaciones';

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _backgroundTapSub;
  StreamSubscription<String>? _tokenRefreshSub;
  bool _localNotificationsReady = false;

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

  /// Cancela todos los listeners activos. Llamar al hacer logout.
  void dispose() {
    _foregroundSub?.cancel();
    _foregroundSub = null;

    _backgroundTapSub?.cancel();
    _backgroundTapSub = null;

    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;

    debugPrint('[FCM] Listeners cancelados (logout)');
  }

  // ---------------------------------------------------------------------------
  // Permisos
  // ---------------------------------------------------------------------------

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
    if (_localNotificationsReady) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
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

    _localNotificationsReady = true;
  }

  // ---------------------------------------------------------------------------
  // Token FCM
  // ---------------------------------------------------------------------------

  Future<void> _getAndSaveToken(int userId) async {
    try {
      if (Platform.isIOS) {
        String? apnsToken = await _messaging.getAPNSToken();
        if (apnsToken != null) {
          debugPrint('[FCM] APNs token disponible: $apnsToken');
        } else {
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
        }
      });
    }
  }

  void _setupTokenRefresh(int userId) {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, newToken);
      await _registerTokenWithBackend(newToken, userId);
    });
  }

  // ---------------------------------------------------------------------------
  // Handlers de mensajes
  // ---------------------------------------------------------------------------

  void _setupForegroundHandler() {
    _foregroundSub?.cancel();
    _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
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

  void _setupBackgroundTapHandler() {
    _backgroundTapSub?.cancel();
    _backgroundTapSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleNotificationTap(message.data);
    });
  }

  Future<void> _setupTerminatedTapHandler() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) {
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

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: _encodePayload(data),
    );
  }

  // ---------------------------------------------------------------------------
  // Navegación
  // ---------------------------------------------------------------------------

  void handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    debugPrint('[FCM] Navegando por tipo: $type');

    switch (type) {
      case 'dish_desk_ready':
        final commandId = int.tryParse(data['commandId'] as String? ?? '');
        final itemId = int.tryParse(data['itemId'] as String? ?? '');
        if (commandId == null || itemId == null) break;
        final dishArgs = {'commandId': commandId, 'itemId': itemId};

        void reloadMesas() {
          final pvId = globalContainer.read(sesionProvider).office?.id;
          if (pvId != null) {
            globalContainer.read(restaurantProvider.notifier).reload(pvId);
          }
        }

        if (DishDeskReadyScreen.isVisible) {
          // Estamos en el dish screen → pop de vuelta a mesas, recargar y
          // abrir el dish screen con el nuevo plato.
          DishDeskReadyScreen.isVisible = false;
          Get.back();
          reloadMesas();
          Future.delayed(Duration.zero, () {
            Get.toNamed(AppRoutes.restaurantDishReady, arguments: dishArgs);
          });
        } else if (Get.currentRoute == AppRoutes.restaurantMesas) {
          // Ya estamos en mesas → solo recargar y abrir el dish screen.
          reloadMesas();
          Get.toNamed(AppRoutes.restaurantDishReady, arguments: dishArgs);
        } else {
          // Venimos de otra pantalla → navegar a mesas (que abrirá el dish
          // screen desde su initState al recibir los args).
          Get.toNamed(AppRoutes.restaurantMesas, arguments: dishArgs);
        }
      case 'order_ready':
        final orderNumber = data['orderNumber'] as String? ?? '';
        final typeOrder = data['typeOrder'] as String? ?? '';
        // Si el pay screen está visible, lo cerramos primero para no apilar.
        if (OrderReadyToPayScreen.isVisible) {
          OrderReadyToPayScreen.isVisible = false; // marcar antes del pop
          Get.back();
        }
        if (Get.currentRoute == AppRoutes.ordersRestaurant) {
          final idPuntoVenta =
              globalContainer.read(sesionProvider).office?.id ?? 0;
          globalContainer
              .read(ordersRestaurantProvider.notifier)
              .applyNotificationFilters(
                idPuntoVenta: idPuntoVenta,
                searchTerm: orderNumber.isNotEmpty ? orderNumber : null,
                tipo: typeOrder.isNotEmpty ? typeOrder : null,
                paid: false,
              );
        } else {
          Get.toNamed(AppRoutes.ordersRestaurant, arguments: {
            'orderNumber': orderNumber,
            'typeOrder': typeOrder,
            'paid': false,
          });
        }
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
