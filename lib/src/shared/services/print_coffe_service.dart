import 'package:dio/dio.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import 'package:teki_app/src/utils/constants.dart';

class PrintCoffeException implements Exception {
  final String message;
  PrintCoffeException(this.message);
}

class PrintCoffeService {
  final Dio _dio = ApiClient.dio;

  /// Llama al servicio de impresión Coffe.
  /// Lanza [PrintCoffeException] si hay un error, con:
  /// - Mensaje del backend si el servidor responde con error.
  /// - "Error al imprimir" si es un error de conexión o sin respuesta.
  Future<void> printCoffe(Map<String, dynamic> data) async {
    final printUrl = Environment.printUrl;
    if (printUrl.isEmpty) return;
    try {
      await _dio.post('$printUrl/print-coffe', data: data);
    } on DioException catch (e) {
      if (e.response != null) {
        final body = e.response!.data;
        String? backendMessage;
        if (body is Map) {
          backendMessage = body['message']?.toString() ?? body['error']?.toString();
        } else if (body is String && body.isNotEmpty) {
          backendMessage = body;
        }
        throw PrintCoffeException(backendMessage ?? 'Error al imprimir');
      }
      throw PrintCoffeException('Error al imprimir');
    } catch (_) {
      throw PrintCoffeException('Error al imprimir');
    }
  }
}
