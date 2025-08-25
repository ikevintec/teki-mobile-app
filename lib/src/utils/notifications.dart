import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:teki_app/src/utils/contstants.dart';

void successNotification(
  String message, {
  bool fromTop = true,
  Duration duration = const Duration(seconds: 2),
}) {
  Get.snackbar(
    'Éxito',
    message,
    duration: duration,
    colorText: Colors.white,
    backgroundColor: Colors.green,
    icon: const Icon(
      Icons.check_circle,
      color: Colors.white,
    ),
    snackPosition: fromTop ? SnackPosition.TOP : SnackPosition.BOTTOM,
  );
}

void errorNotification(
  String message, {
  bool fromTop = true,
  Duration duration = const Duration(seconds: 4),
}) {
  Get.snackbar(
    'Error',
    message,
    duration: duration,
    colorText: Colors.white,
    backgroundColor: Colors.red,
    icon: const Icon(
      Icons.error,
      color: Colors.white,
    ),
    snackPosition: fromTop ? SnackPosition.TOP : SnackPosition.BOTTOM,
  );
}

void infoNotification(
  String message, {
  bool fromTop = true,
  Duration duration = const Duration(seconds: 2),
}) {
  Get.snackbar(
    'Información',
    message,
    duration: duration,
    colorText: Colors.white,
    backgroundColor: ColorSchema.primaryColor,
    icon: const Icon(
      Icons.info,
      color: Colors.white,
    ),
    snackPosition: fromTop ? SnackPosition.TOP : SnackPosition.BOTTOM,
  );
}

void warningNotification(
  String message, {
  bool fromTop = true,
  Duration duration = const Duration(seconds: 2),
}) {
  Get.snackbar(
    'Advertencia',
    message,
    duration: duration,
    colorText: Colors.white,
    backgroundColor: Colors.orangeAccent,
    icon: const Icon(
      Icons.warning,
      color: Colors.white,
    ),
    snackPosition: fromTop ? SnackPosition.TOP : SnackPosition.BOTTOM,
  );
}