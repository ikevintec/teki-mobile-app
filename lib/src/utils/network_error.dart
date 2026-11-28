import 'package:dio/dio.dart';
import 'package:teki_app/src/shared/services/internet_monitor.dart';

class NetworkMessages {
  static const offline =
      'Sin conexión a Internet. Revisa tu Wi-Fi o tus datos móviles.';
  static const unavailable =
      'El servicio no está disponible en este momento. Inténtalo más tarde.';
  static const unreachable =
      'No pudimos conectar con el servicio. Inténtalo de nuevo.';
  static const timeout =
      'El servicio está tardando en responder. Inténtalo de nuevo.';
}

/// No deduce falta de Internet a partir de un reset, DNS o timeout de la API.
Future<String?> networkErrorMessage(
  DioException error,
  InternetMonitor monitor,
) async {
  if (error.type == DioExceptionType.cancel) return null;
  final status = error.response?.statusCode;
  if (status != null) {
    monitor.markReachable();
    return status >= 500 ? NetworkMessages.unavailable : null;
  }
  final state = await monitor.refresh();
  if (state == InternetState.disconnected) return NetworkMessages.offline;
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout) {
    return NetworkMessages.timeout;
  }
  return NetworkMessages.unreachable;
}
