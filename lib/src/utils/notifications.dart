import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:teki_app/src/utils/contstants.dart';

void successNotification(String message, {bool fromTop = true}) {
  Get.snackbar(
    'Éxito',
    message,
    duration: const Duration(seconds: 2),
    colorText: Colors.white,
    backgroundColor: Colors.green,
    icon: const Icon(
      Icons.check_circle,
      color: Colors.white,
    ),
    snackPosition: fromTop ? SnackPosition.TOP : SnackPosition.BOTTOM,
  );
}

void errorNotification(String message, {bool fromTop = true}) {
  Get.snackbar(
    'Error',
    message,
    duration: const Duration(seconds: 4),
    colorText: Colors.white,
    backgroundColor: Colors.red,
    icon: const Icon(
      Icons.error,
      color: Colors.white,
    ),
    snackPosition: fromTop ? SnackPosition.TOP : SnackPosition.BOTTOM,
  );
}

void infoNotification(String message, {bool fromTop = true}) {
  Get.snackbar(
    'Información',
    message,
    duration: const Duration(seconds: 2),
    colorText: Colors.white,
    backgroundColor: ColorSchema.primaryColor,
    icon: const Icon(
      Icons.info,
      color: Colors.white,
    ),
    snackPosition: fromTop ? SnackPosition.TOP : SnackPosition.BOTTOM,
  );
}

void warningNotification(String message, {bool fromTop = true}) {
  Get.snackbar(
    'Advertencia',
    message,
    duration: const Duration(seconds: 2),
    colorText: Colors.white,
    backgroundColor: Colors.orangeAccent,
    icon: const Icon(
      Icons.warning,
      color: Colors.white,
    ),
    snackPosition: fromTop ? SnackPosition.TOP : SnackPosition.BOTTOM,
  );
}