import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/teki_model/totalesComprobantes.dart';
import 'package:teki_app/src/data/models/teki_model/totalesFormaPagos.dart';
import 'package:teki_app/src/domain/datasource/tickets_sale_datasource.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/utils/notifications.dart';
import 'package:teki_app/src/utils/api_client.constant.dart'; // Asegúrate de tener esto

class RemoteTicketSaleDatasource extends TicketSaleDatasource {
  final Dio dio = ApiClient.dio;

  /// Obtiene las series disponibles por oficina (punto de venta) y tipo de documento
  @override
  Future<List<String>> getSeriesPorOficina(
      int officeId, String tipoDocumento) async {
    try {
      final response = await dio.get(
        '/series/office/$officeId',
        queryParameters: {
          'tipoDocumento': tipoDocumento,
        },
      );

      final List<dynamic> rawList = response.data;

      // Extrae solo los valores del campo "numero" como String
      final List<String> numeros = rawList
          .map((item) => item['numero']?.toString())
          .where((numero) => numero != null && numero!.isNotEmpty)
          .cast<String>()
          .toList();

      return numeros;
    } catch (e) {
      errorNotification("Error al obtener series por oficina: $e");
      return Future.error(e.toString());
    }
  }

  /// Obtiene el siguiente número de comprobante según tipoDocumento y serie
  @override
  Future<Ticket> getNextTicketNumber(String tipoDocumento, String serie) async {
    try {
      final response = await dio.get(
        '/tickets/operations/next-number', // ✅ RUTA relativa (baseUrl ya está en ApiClient)
        queryParameters: {
          'tipoDocumento': tipoDocumento,
          'serie': serie,
        },
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

      return Ticket(
        serie: serie,
        numero: numero,
        tipoComprobante: tipoDocumento,
      );
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data['message'] ?? e.message ?? 'Error de conexión';
      errorNotification(errorMessage);
      return Future.error(errorMessage);
    } catch (e) {
      errorNotification(e.toString());
      return Future.error(e.toString());
    }
  }

  /// Crea un nuevo ticket de venta
  @override
  Future<Ticket> createTicket(Ticket ticket) async {
    try {
      final response = await dio.post(
        '/tickets',
        data: ticket.toJson(),
      );
      return Ticket.fromJson(response.data);
    } catch (e) {
      errorNotification("Error al crear ticket: $e");
      return Future.error(e.toString());
    }
  }

  /// Obtiene los tickets existentes por tipoDocumento y serie
  @override
  Future<List<Ticket>> getTicketNumeros(
      String tipoDocumento, String serie) async {
    try {
      final response = await dio.get(
        '/tickets/search',
        queryParameters: {
          'tipoDocumento': tipoDocumento,
          'serie': serie,
        },
      );

      final data = response.data as List;
      return data.map((json) => Ticket.fromJson(json)).toList();
    } catch (e) {
      errorNotification("Error al obtener tickets: $e");
      return Future.error(e.toString());
    }
  }

  /// Obtiene los comprobantes según los filtros básicos
  /// Obtiene los comprobantes según los filtros básicos
  @override
  Future<List<Ticket>> getComprobantes(Map<String, dynamic> params) async {
    try {
      final response = await dio.get(
        '/tickets',
        queryParameters: params,
      );

      final List<dynamic> content = response.data['content'];

      return content
          .map((json) {
            try {
              final fixedJson = Map<String, dynamic>.from(json);

              if (fixedJson['fechaEmisionDate'] is int) {
                fixedJson['fechaEmisionDate'] =
                    DateTime.fromMillisecondsSinceEpoch(
                            fixedJson['fechaEmisionDate'])
                        .toIso8601String();
              }
              if (fixedJson['createdOn'] is int) {
                fixedJson['createdOn'] =
                    DateTime.fromMillisecondsSinceEpoch(fixedJson['createdOn'])
                        .toIso8601String();
              }
              if (fixedJson['fechaRegistro'] is int) {
                fixedJson['fechaRegistro'] =
                    DateTime.fromMillisecondsSinceEpoch(
                            fixedJson['fechaRegistro'])
                        .toIso8601String();
              }

              if (fixedJson['cliente'] is Map<String, dynamic>) {
                final cliente = Map<String, dynamic>.from(fixedJson['cliente']);
                if (cliente['fechaNacimiento'] is int) {
                  cliente['fechaNacimiento'] =
                      DateTime.fromMillisecondsSinceEpoch(
                              cliente['fechaNacimiento'])
                          .toIso8601String();
                }
                if (cliente['createdOn'] is int) {
                  cliente['createdOn'] =
                      DateTime.fromMillisecondsSinceEpoch(cliente['createdOn'])
                          .toIso8601String();
                }
                fixedJson['cliente'] = cliente;
              }

              return Ticket.fromJson(fixedJson);
            } catch (e) {
              print("❌ Error al convertir un ticket: $e");
              print("🧾 Datos problemáticos: $json");
              return null;
            }
          })
          .whereType<Ticket>()
          .toList();
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ?? e.message ?? 'Error de conexión';
      print("Error al obtener comprobantes 1: $message");
      return Future.error(message);
    } catch (e, stack) {
      print("❌ Excepción: $e");
      print("📍 Stack: $stack");
      print("Error al obtener comprobantes 2: $e");
      return Future.error(e.toString());
    }
  }

  @override
  Future<List<PaymentMethodTotal>> getTotalesPorFormaPago({
    required String filtroDesde,
    required String filtroHasta,
    required String filtroRucEmisor,
    required int idPuntoVenta,
    required int idVendedor,
  }) async {
    try {
      final response = await dio.get(
        '/tickets/operations/totales-forma-pago',
        queryParameters: {
          'filtroCanal': 'PLATFORM',
          'pageNumber': '0',
          'perPage': '10',
          'filtroDesde': filtroDesde,
          'filtroHasta': filtroHasta,
          'filtroRucEmisor': filtroRucEmisor,
          'idPuntoVenta': idPuntoVenta,
          'idVendedor': idVendedor,
          'sortOrder': '1',
        },
      );

      final List<dynamic> content = response.data;

      return content
          .map((json) {
            try {
              final fixedJson = Map<String, dynamic>.from(json);
              return PaymentMethodTotal.fromJson(fixedJson);
            } catch (e) {
              print("❌ Error al convertir un método de pago: $e");
              print("💳 Datos problemáticos: $json");
              return null;
            }
          })
          .whereType<PaymentMethodTotal>()
          .toList();
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ?? e.message ?? 'Error de conexión';
      errorNotification(
          "Error al obtener totales por forma de pago 1: $message");
      return Future.error(message);
    } catch (e, stack) {
      print("❌ Excepción: $e");
      print("📍 Stack: $stack");
      errorNotification("Error al obtener totales por forma de pago 2: $e");
      return Future.error(e.toString());
    }
  }

  @override
  Future<List<TotalesPorMoneda>> getTotalesPorMoneda({
    required String filtroDesde,
    required String filtroHasta,
    required String filtroRucEmisor,
    required int idPuntoVenta,
    required int idVendedor,
  }) async {
    try {
      final response = await dio.get(
        '/tickets/operations/totales',
        queryParameters: {
          'filtroCanal': 'PLATFORM',
          'pageNumber': '0',
          'perPage': '10',
          'filtroDesde': filtroDesde,
          'filtroHasta': filtroHasta,
          'filtroRucEmisor': filtroRucEmisor,
          'idPuntoVenta': idPuntoVenta,
          'idVendedor': idVendedor,
          'sortOrder': '1',
          'porDetalle': 'false',
        },
      );

      final List<dynamic> content = response.data;

      return content
          .map((json) {
            try {
              final fixedJson = Map<String, dynamic>.from(json);
              return TotalesPorMoneda.fromJson(fixedJson);
            } catch (e) {
              print("❌ Error al convertir un total por moneda: $e");
              print("💰 Datos problemáticos: $json");
              return null;
            }
          })
          .whereType<TotalesPorMoneda>()
          .toList();
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ?? e.message ?? 'Error de conexión';
      errorNotification("Error al obtener totales por moneda 1: $message");
      return Future.error(message);
    } catch (e, stack) {
      print("❌ Excepción: $e");
      print("📍 Stack: $stack");
      errorNotification("Error al obtener totales por moneda 2: $e");
      return Future.error(e.toString());
    }
  }
}
