import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/teki_model/quotation.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/domain/datasource/quotation_datasource.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import 'package:teki_app/src/utils/notifications.dart';

class RemoteQuotationDatasource extends QuotationDatasource {
  final Dio dio = ApiClient.dio;

  /// Crea una cotización. Agrega los campos propios de cotización
  /// que el backend espera en este endpoint y que no existen en Ticket.
  @override
  Future<Ticket> createQuotation(Ticket ticket) async {
    try {
      final data = ticket.toJson();
      data['ofertaValido'] = '';
      data['tiempoEntrega'] = '';
      final response = await dio.post(
        '/quotation',
        data: data,
      );
      return Ticket.fromJson(response.data);
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      final resData = e.response?.data;
      final message = (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ??
          e.message ??
          'Error desconocido del servidor';
      return Future.error(message);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  /// Actualiza una cotización existente (modo edición).
  /// El endpoint no devuelve la cotización actualizada en el body,
  /// por lo que se retorna el mismo ticket enviado (ya trae el id).
  @override
  Future<Ticket> updateQuotation(Ticket ticket) async {
    try {
      await dio.put(
        '/quotation',
        data: ticket.toJson(),
      );
      return ticket;
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      final resData = e.response?.data;
      final message = (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ??
          e.message ??
          'Error desconocido del servidor';
      return Future.error(message);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  /// Obtiene el siguiente número de cotización según tipoDocumento y serie
  @override
  Future<int> getNextQuotationNumber(String tipoDocumento, String serie) async {
    try {
      final response = await dio.get(
        '/quotation/next-number',
        queryParameters: {
          'tipoDocumento': tipoDocumento,
          'serie': serie,
        },
      );

      if (response.data is int) {
        return response.data;
      } else if (response.data is String) {
        return int.tryParse(response.data) ?? 0;
      } else if (response.data is Map && response.data['numero'] != null) {
        return int.tryParse(response.data['numero'].toString()) ?? 0;
      }
      throw Exception('Formato de respuesta inválido');
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      final resData = e.response?.data;
      final message = (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ??
          e.message ??
          'Error desconocido del servidor';
      return Future.error(message);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  /// Obtiene una cotización por id
  @override
  Future<Quotation> getQuotationById(int id) async {
    try {
      final response = await dio.get('/quotation/$id');
      return Quotation.fromJson(response.data);
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      final resData = e.response?.data;
      final message = (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ??
          e.message ??
          'Error desconocido del servidor';
      return Future.error(message);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  /// Lista paginada de cotizaciones según filtros (fecha, serie, número, estado, etc.)
  @override
  Future<List<Quotation>> getQuotations(Map<String, dynamic> params) async {
    try {
      final response = await dio.get(
        '/quotation',
        queryParameters: params,
      );

      final List<dynamic> content = response.data['content'];

      return content
          .map((json) {
            try {
              return Quotation.fromJson(Map<String, dynamic>.from(json));
            } catch (e) {
              return null;
            }
          })
          .whereType<Quotation>()
          .toList();
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      if (e.response == null) {
        errorNotification('Sin conexión a internet');
        return Future.error('Sin conexión a internet');
      }
      final resData = e.response?.data;
      final message = (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ??
          e.message ??
          'Error de conexión';
      return Future.error(message);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  /// Anula (elimina) una cotización por id
  @override
  Future<void> deleteQuotation(int id) async {
    try {
      await dio.delete('/quotation/$id');
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      final resData = e.response?.data;
      final message = (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ??
          e.message ??
          'Error desconocido del servidor';
      return Future.error(message);
    } catch (e) {
      return Future.error(e.toString());
    }
  }
}
