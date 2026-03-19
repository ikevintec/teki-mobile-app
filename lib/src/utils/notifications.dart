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

void errorNotification(
  String message, {
  bool fromTop = true,
  Duration duration = const Duration(seconds: 3),
  ToastificationStyle style = ToastificationStyle.fillColored,
}) {
  toastification.show(
    type: ToastificationType.error,
    style: style,
    title: Text(message),
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