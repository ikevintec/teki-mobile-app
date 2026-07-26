import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/response/estado_sunat_response.dart';
import 'package:teki_app/src/data/models/teki_model/totales_comprobantes.dart';
import 'package:teki_app/src/data/models/teki_model/totales_forma_pagos.dart';

import 'package:teki_app/src/domain/datasource/tickets_sale_datasource.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/utils/notifications.dart';
import 'package:teki_app/src/utils/api_client.constant.dart'; // Asegúrate de tener esto

class RemoteTicketSaleDatasource extends TicketSaleDatasource {
  final Dio dio = ApiClient.dio;

  /// Obtiene las series disponibles por oficina (punto de venta) y tipo de documento
  @override
  Future<List<String>> getSeriesPorOficina(
    int officeId,
    String tipoDocumento,
  ) async {
    try {
      final response = await dio.get(
        '/series/office/$officeId',
        queryParameters: {'tipoDocumento': tipoDocumento},
      );

      final List<dynamic> rawList = response.data;

      // Extrae solo los valores del campo "numero" como String
      final List<String> numeros = rawList
          .map((item) => item['numero']?.toString())
          .where((numero) => numero != null && numero.isNotEmpty)
          .cast<String>()
          .toList();

      return numeros;
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      if (e.response == null) {
        errorNotification('Sin conexión a internet');
        return Future.error('Sin conexión a internet');
      }
      errorNotification("Error al obtener series por oficina: $e");
      return Future.error(e.toString());
    } catch (e) {
      errorNotification("Error al obtener series por oficina: $e");
      return Future.error(e.toString());
    }
  }

  /// Obtiene el siguiente número de comprobante según tipoDocumento y serie
  @override
  Future<int> getNextTicketNumber(String tipoDocumento, String serie) async {
    try {
      final response = await dio.get(
        '/tickets/operations/next-number',
        queryParameters: {'tipoDocumento': tipoDocumento, 'serie': serie},
      );

      int numero;

      if (response.data is int) {
        numero = response.data;
      } else if (response.data is String) {
        numero = int.tryParse(response.data) ?? 0;
      } else if (response.data is Map && response.data['numero'] != null) {
        numero = int.tryParse(response.data['numero'].toString()) ?? 0;
      } else {
        throw Exception('Formato de respuesta inválido');
      }

      return numero;
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      if (e.response == null) {
        errorNotification('Sin conexión a internet');
        return Future.error('Sin conexión a internet');
      }
      final resData = e.response?.data;
      final errorMessage =
          (resData is Map
              ? (resData['mensaje'] ?? resData['message'])
              : null) ??
          e.message ??
          'Error de conexión';
      errorNotification(errorMessage);
      return Future.error(errorMessage);
    } catch (e) {
      errorNotification(e.toString());
      return Future.error(e.toString());
    }
  }

  /// Obtiene los tickets existentes por tipoDocumento y serie
  @override
  Future<List<Ticket>> getTicketNumeros(
    String tipoDocumento,
    String serie,
  ) async {
    try {
      final response = await dio.get(
        '/tickets/search',
        queryParameters: {'tipoDocumento': tipoDocumento, 'serie': serie},
      );

      final data = response.data as List;
      return data.map((json) => Ticket.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      if (e.response == null) {
        errorNotification('Sin conexión a internet');
        return Future.error('Sin conexión a internet');
      }
      final resData = e.response?.data;
      final message =
          (resData is Map
              ? (resData['mensaje'] ?? resData['message'])
              : null) ??
          e.message ??
          'Error desconocido del servidor';
      return Future.error(message);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  /// Obtiene los comprobantes según los filtros básicos
  @override
  Future<List<Ticket>> getComprobantes(Map<String, dynamic> params) async {
    try {
      final response = await dio.get('/tickets', queryParameters: params);

      final List<dynamic> content = response.data['content'];

      return content
          .map((json) {
            try {
              final fixedJson = Map<String, dynamic>.from(json);

              if (fixedJson['fechaEmisionDate'] is int) {
                fixedJson['fechaEmisionDate'] =
                    DateTime.fromMillisecondsSinceEpoch(
                      fixedJson['fechaEmisionDate'],
                    ).toIso8601String();
              }
              if (fixedJson['createdOn'] is int) {
                fixedJson['createdOn'] = DateTime.fromMillisecondsSinceEpoch(
                  fixedJson['createdOn'],
                ).toIso8601String();
              }
              if (fixedJson['fechaRegistro'] is int) {
                fixedJson['fechaRegistro'] =
                    DateTime.fromMillisecondsSinceEpoch(
                      fixedJson['fechaRegistro'],
                    ).toIso8601String();
              }

              if (fixedJson['cliente'] is Map<String, dynamic>) {
                final cliente = Map<String, dynamic>.from(fixedJson['cliente']);
                if (cliente['fechaNacimiento'] is int) {
                  cliente['fechaNacimiento'] =
                      DateTime.fromMillisecondsSinceEpoch(
                        cliente['fechaNacimiento'],
                      ).toIso8601String();
                }
                if (cliente['createdOn'] is int) {
                  cliente['createdOn'] = DateTime.fromMillisecondsSinceEpoch(
                    cliente['createdOn'],
                  ).toIso8601String();
                }
                fixedJson['cliente'] = cliente;
              }

              return Ticket.fromJson(fixedJson);
            } catch (e) {
              debugPrint("❌ Error al convertir un ticket: $e");
              debugPrint("🧾 Datos problemáticos: $json");
              return null;
            }
          })
          .whereType<Ticket>()
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
      final message =
          (resData is Map
              ? (resData['mensaje'] ?? resData['message'])
              : null) ??
          e.message ??
          'Error de conexión';
      debugPrint("Error al obtener comprobantes 1: $message");
      return Future.error(message);
    } catch (e, stack) {
      debugPrint("❌ Excepción: $e");
      debugPrint("📍 Stack: $stack");
      debugPrint("Error al obtener comprobantes 2: $e");
      return Future.error(e.toString());
    }
  }

  @override
  Future<List<TotalesPorMoneda>> getTotalesPorMoneda(
    Map<String, dynamic> params,
  ) async {
    try {
      final response = await dio.get(
        '/tickets/operations/totales',
        queryParameters: params,
      );

      final List<dynamic> content = response.data;

      return content
          .map((json) {
            try {
              final fixedJson = Map<String, dynamic>.from(json);
              return TotalesPorMoneda.fromJson(fixedJson);
            } catch (e) {
              debugPrint("❌ Error al convertir un total por moneda: $e");
              return null;
            }
          })
          .whereType<TotalesPorMoneda>()
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
      final message =
          (resData is Map
              ? (resData['mensaje'] ?? resData['message'])
              : null) ??
          e.message ??
          'Error de conexión';
      errorNotification("Error al obtener totales por moneda 1: $message");
      return Future.error(message);
    } catch (e, stack) {
      debugPrint("❌ Excepción: $e");
      debugPrint("📍 Stack: $stack");
      errorNotification("Error al obtener totales por moneda 2: $e");
      return Future.error(e.toString());
    }
  }

  @override
  Future<List<TotalVentasFormaPago>> getTotalesFormaPago(
    Map<String, dynamic> params,
  ) async {
    try {
      final response = await dio.get(
        '/tickets/operations/totales-forma-pago',
        queryParameters: params,
      );
      return (response.data as List)
          .map((e) => TotalVentasFormaPago.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      final resData = e.response?.data;
      final message = (resData is Map
              ? (resData['mensaje'] ?? resData['message'])
              : null) ??
          e.message ??
          'Error al obtener totales por forma de pago';
      return Future.error(message);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  @override
  Future<Ticket> getTicketById(int id) async {
    try {
      final response = await dio.get('/tickets/$id');
      return Ticket.fromJson(response.data);
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      if (e.response == null) {
        errorNotification('Sin conexión a internet');
        return Future.error('Sin conexión a internet');
      }
      final resData = e.response?.data;
      final message =
          (resData is Map
              ? (resData['mensaje'] ?? resData['message'])
              : null) ??
          e.message ??
          'Error desconocido del servidor';
      return Future.error(message);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  /// Crea un nuevo ticket de venta
  @override
  Future<Ticket> createTicket(Ticket ticket) async {
    try {
      final data = ticket.toJson();
      // Si el ticket proviene de "Generar venta" desde una cotización, solo se
      // envía el id de la cotización (el backend la concreta con esa referencia).
      if (ticket.cotizacion?.id != null) {
        data['cotizacion'] = {'id': ticket.cotizacion!.id};
      }
      final response = await dio.post('/tickets', data: data);
      return Ticket.fromJson(response.data);
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      final resData = e.response?.data;
      final message =
          (resData is Map
              ? (resData['mensaje'] ?? resData['message'])
              : null) ??
          e.message ??
          'Error desconocido del servidor';
      return Future.error(message);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  @override
  Future<EstadoSunatResponse> consultarEstadoSunat(Ticket ticket) async {
    try {
      final response = await dio.post(
        '/tickets/consultarEstadoSunat',
        data: ticket.toJson(),
      );
      return EstadoSunatResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      if (e.response == null) {
        errorNotification('Sin conexión a internet');
        return Future.error('Sin conexión a internet');
      }
      final resData = e.response?.data;
      final message =
          (resData is Map
              ? (resData['mensaje'] ?? resData['message'])
              : null) ??
          e.message ??
          'Error de conexión';
      return Future.error(message);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  /// Anula un comprobante por su identificador de documento
  @override
  Future<void> anularComprobante(
    String identificadorDocumento,
    String motivo,
  ) async {
    try {
      await dio.post(
        '/voided/$identificadorDocumento',
        data: {'motivo': motivo},
      );
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      if (e.response == null) {
        errorNotification('Sin conexión a internet');
        return Future.error('Sin conexión a internet');
      }
      final resData = e.response?.data;
      final message =
          (resData is Map
              ? (resData['mensaje'] ?? resData['message'])
              : null) ??
          e.message ??
          'Error desconocido del servidor';
      return Future.error(message);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  /// Actualizar un ticket existente
  @override
  Future<Ticket> updateTicket(Ticket ticket) async {
    try {
      final response = await dio.put('/tickets', data: ticket.toJson());
      return Ticket.fromJson(response.data);
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      final resData = e.response?.data;
      final message =
          (resData is Map
              ? (resData['mensaje'] ?? resData['message'])
              : null) ??
          e.message ??
          'Error desconocido del servidor';
      return Future.error(message);
    } catch (e) {
      return Future.error(e.toString());
    }
  }
}
