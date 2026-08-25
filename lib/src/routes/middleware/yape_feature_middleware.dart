import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:teki_app/main.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/routes/app_routes.dart';

class YapeFeatureMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final habilitado = globalContainer
            .read(sesionProvider)
            .config
            ?.verNotificacionYape ==
        true;
    if (!habilitado) {
      return const RouteSettings(name: AppRoutes.dashboard);
    }
    return null;
  }
}
