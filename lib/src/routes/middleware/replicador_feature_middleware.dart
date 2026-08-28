import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:teki_app/main.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/shared/services/yape_notification_service.dart';

class ReplicadorFeatureMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final session = globalContainer.read(sesionProvider);
    final enabled =
        session.config?.verNotificacionYape == true &&
        YapeNotificationService.instance.isSupported &&
        session.hasPermission('PERMITIR_GESTIONAR_NOTIFICACIONES_BILLETERAS');
    return enabled ? null : const RouteSettings(name: AppRoutes.dashboard);
  }
}
