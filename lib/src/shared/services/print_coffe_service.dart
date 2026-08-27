import 'package:dio/dio.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import 'package:teki_app/src/utils/constants.dart';

class PrintCoffeException implements Exception {
  final String message;
  PrintCoffeException(this.message);
}

/// Resultado del servicio Coffe: responde 200 aun cuando no imprime
/// (p. ej. cliente de impresión apagado), y lo indica en [printed]/[message].
class PrintCoffeResult {
  final bool printed;
  final String? message;
  PrintCoffeResult({required this.printed, this.message});
}

class PrintCoffeService {
  final Dio _dio = ApiClient.dio;

  /// Llama al servicio de impresión Coffe y devuelve su resultado.
  /// Lanza [PrintCoffeException] si hay un error, con:
  /// - Mensaje del backend si el servidor responde con error.
  /// - "Error al imprimir" si es un error de conexión o sin respuesta.
  Future<PrintCoffeResult> printCoffe(Map<String, dynamic> data) async {
    final printUrl = Environment.printUrl;
    if (printUrl.isEmpty) {
      return PrintCoffeResult(printed: false, message: 'Servicio de impresión no configurado.');
    }
    try {
      final response = await _dio.post('$printUrl/print-coffe', data: data);
      final body = response.data;
      if (body is Map) {
        return PrintCoffeResult(
          // Si el body no trae "printed" (versiones antiguas de Coffe),
          // se asume impreso para no alertar en falso.
          printed: body['printed'] != false,
          message: body['message']?.toString(),
        );
      }
      return PrintCoffeResult(printed: true);
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
