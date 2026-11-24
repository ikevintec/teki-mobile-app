import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

void successNotification(
  String message, {
  bool fromTop = true,
  Duration duration = const Duration(seconds: 2),
  ToastificationStyle style = ToastificationStyle.fillColored,
}) {
  toastification.show(
    type: ToastificationType.success,
    style: style,
    title: Text(message),
    autoCloseDuration: duration,
    alignment: fromTop ? Alignment.topCenter : Alignment.bottomCenter,
    dragToClose: true,
    showProgressBar: false,
    closeOnClick: true,
  );
}

String? _ultimoError;
DateTime _ultimoErrorEn = DateTime.fromMillisecondsSinceEpoch(0);

/// Muchas pantallas pasan `e.toString()`: si es el texto técnico de Dio (en
/// inglés, "DioException ... This exception was thrown because...") se muestra
/// un mensaje entendible en su lugar.
String mensajeErrorLegible(String message) {
  final tecnico = message.contains('DioException') ||
      message.contains('This exception was thrown') ||
      message.contains('SocketException') ||
      message.contains('Connection refused');
  if (!tecnico) return message;
  if (message.contains('connection') ||
      message.contains('Connection') ||
      message.contains('SocketException') ||
      message.contains('timeout')) {
    return 'No hay conexión con el servidor. Revisa tu internet e inténtalo de nuevo.';
  }
  return 'No se pudo completar la operación. Inténtalo de nuevo.';
}

void errorNotification(
  String message, {
  bool fromTop = true,
  Duration duration = const Duration(seconds: 3),
  ToastificationStyle style = ToastificationStyle.fillColored,
}) {
  final legible = mensajeErrorLegible(message);
  // El mismo error repetido (varias peticiones que fallan juntas) se muestra
  // una sola vez en vez de apilar avisos iguales.
  final ahora = DateTime.now();
  if (legible == _ultimoError &&
      ahora.difference(_ultimoErrorEn) < const Duration(seconds: 2)) {
    return;
  }
  _ultimoError = legible;
  _ultimoErrorEn = ahora;
  toastification.show(
    type: ToastificationType.error,
    style: style,
    title: Text(legible),
    autoCloseDuration: duration,
    alignment: fromTop ? Alignment.topCenter : Alignment.bottomCenter,
    dragToClose: true,
    showProgressBar: false,
    closeOnClick: true,
  );
}

void infoNotification(
  String message, {
  bool fromTop = true,
  Duration duration = const Duration(seconds: 2),
  ToastificationStyle style = ToastificationStyle.fillColored,
}) {
  toastification.show(
    type: ToastificationType.info,
    style: style,
    title: Text(message),
    autoCloseDuration: duration,
    alignment: fromTop ? Alignment.topCenter : Alignment.bottomCenter,
    dragToClose: true,
    showProgressBar: false,
    closeOnClick: true,
  );
}

void warningNotification(
  String message, {
  bool fromTop = true,
  Duration duration = const Duration(seconds: 2),
  ToastificationStyle style = ToastificationStyle.fillColored,
}) {
  toastification.show(
    type: ToastificationType.warning,
    style: style,
    title: Text(message),
    autoCloseDuration: duration,
    alignment: fromTop ? Alignment.topCenter : Alignment.bottomCenter,
    dragToClose: true,
    showProgressBar: false,
    closeOnClick: true,
  );
}