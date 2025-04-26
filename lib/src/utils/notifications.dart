
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:teki_app/src/utils/contstants.dart';

void successNotification(String message) {
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
  );
}

void errorNotification(String message) {
  Get.snackbar(
    'Error',
    message,
    duration: const Duration(seconds: 2),
    colorText: Colors.white,
    backgroundColor: Colors.red,
    icon: const Icon(
      Icons.error,
      color: Colors.white,
    ),
  );
}

void infoNotification(String message) {
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
  );
}