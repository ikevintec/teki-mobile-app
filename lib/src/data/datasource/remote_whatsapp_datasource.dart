import 'package:dio/dio.dart';
import 'package:teki_app/main.dart';
import 'package:teki_app/src/domain/datasource/whatsapp_datasource.dart';
import 'package:teki_app/src/data/models/whatsapp/whatsapp_message_request.dart';
import 'package:teki_app/src/data/models/whatsapp/whatsapp_document_request.dart';
import 'package:teki_app/src/data/models/whatsapp/whatsapp_evolution_media_request.dart';
import 'package:teki_app/src/data/models/whatsapp/whatsapp_socket_request.dart';
import 'package:teki_app/src/data/models/whatsapp/whatsapp_response.dart';
import 'package:teki_app/src/providers/auth/login.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WhatsappDataSourceImpl implements WhatsappDataSource {
  final Dio dio;
  late final Dio _whatsappClient;
  late final Dio _wsClient;
  
  WhatsappDataSourceImpl({Dio? dio}) 
      : dio = dio ?? ApiClient.dio {
    _initializeWhatsappClients();
  }

  void _initializeWhatsappClients() {
    _whatsappClient = Dio(BaseOptions(
      baseUrl: Environment.apiUrl
    ));

    // Cliente para WebSocket también sin timeouts
    _wsClient = Dio(BaseOptions(
      baseUrl: Environment.apiUrl.replaceAll('/api', '/ws'),
    ));

    // Agregar interceptores para autenticación en ambos clientes
    _addAuthInterceptors(_whatsappClient);
    _addAuthInterceptors(_wsClient);
  }

  void _addAuthInterceptors(Dio client) {
    client.interceptors.addAll([
      LogInterceptor(
        request: true,
        requestHeader: true,
        responseHeader: true,
        error: true,
        requestBody: true,
        responseBody: true,
        logPrint: (obj) {
          print('--->: $obj');
        },
      ),
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          bool isLoggingOut = false;
          if (e.response?.statusCode == 401 && !isLoggingOut) {
            isLoggingOut = true;
            globalContainer.read(authStateProvider.notifier).logout();
          }
          return handler.next(e);
        },
      )
    ]);
  }

  Map<String, String> get _headersWithHideLoader => {
    'hideLoader': 'S',
  };

  Map<String, String> get _headersWithPrinting => {
    'hideLoader': 'S',
    'isPrinting': 'S',
  };

  @override
  Future<WhatsappResponse> sendMessage(WhatsappMessageRequest request) async {
    try {
      await _whatsappClient.post(
        '/whatsapp/messages',
        data: request.toJson(),
        options: Options(headers: _headersWithHideLoader),
      );

      return WhatsappResponse(
        success: true,
        message: 'Mensaje enviado correctamente',
      );
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      return WhatsappResponse(
        success: false,
        message: 'Error al enviar mensaje: $e',
      );
    } catch (e) {
      return WhatsappResponse(
        success: false,
        message: 'Error al enviar mensaje: $e',
      );
    }
  }

  @override
  Future<WhatsappResponse> sendDocument(WhatsappDocumentRequest request) async {
    try {
      await _whatsappClient.post(
        '/whatsapp/documents',
        data: request.toJson(),
        options: Options(headers: _headersWithHideLoader),
      );

      return WhatsappResponse(
        success: true,
        message: 'Documento enviado correctamente'
      );
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      return WhatsappResponse(
        success: false,
        message: 'Error al enviar documento: $e',
      );
    } catch (e) {
      return WhatsappResponse(
        success: false,
        message: 'Error al enviar documento: $e',
      );
    }
  }

  @override
  Future<WhatsappResponse> evolutionSendMedia(WhatsappEvolutionMediaRequest request) async {
    try {
      await _whatsappClient.post(
        '/whatsapp/evolution/send-media',
        data: request.toJson(),
        options: Options(headers: _headersWithHideLoader),
      );

      return WhatsappResponse(
        success: true,
        message: 'Media enviado correctamente',
      );
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      return WhatsappResponse(
        success: false,
        message: 'Error al enviar media: $e',
      );
    } catch (e) {
      return WhatsappResponse(
        success: false,
        message: 'Error al enviar media: $e',
      );
    }
  }

  @override
  Future<WhatsappResponse> sendMessageSocket(WhatsappSocketRequest request) async {
    try {
      final response = await _wsClient.post(
        '/send-message-whatsapp-socket',
        data: request.toJson(),
        options: Options(headers: _headersWithPrinting),
      );

      final data = response.data;
      return WhatsappResponse(
        success: data['sended'] ?? false,
        message: data['sended'] ? 'Mensaje enviado correctamente' : 'Error al enviar mensaje'
      );
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      return WhatsappResponse(
        success: false,
        message: 'Error al enviar mensaje por socket: $e',
      );
    } catch (e) {
      return WhatsappResponse(
        success: false,
        message: 'Error al enviar mensaje por socket: $e',
      );
    }
  }

  @override
  Future<WhatsappResponse> closeSessionWhatsapp(Map<String, dynamic> data) async {
    try {
      await _wsClient.post(
        '/whatsapp-session-logout',
        data: data,
        options: Options(headers: _headersWithPrinting),
      );

      return WhatsappResponse(
        success: true,
        message: 'Sesión cerrada correctamente'      
        );
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      return WhatsappResponse(
        success: false,
        message: 'Error al cerrar sesión: $e',
      );
    } catch (e) {
      return WhatsappResponse(
        success: false,
        message: 'Error al cerrar sesión: $e',
      );
    }
  }

  @override
  Future<WhatsappResponse> getInstanceWhatsapp() async {
    try {
      await _whatsappClient.get('/whatsapp/evolution/get-instance');

      return WhatsappResponse(
        success: true,
        message: 'Instancia obtenida correctamente',
      );
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      return WhatsappResponse(
        success: false,
        message: 'Error al obtener instancia: $e',
      );
    } catch (e) {
      return WhatsappResponse(
        success: false,
        message: 'Error al obtener instancia: $e',
      );
    }
  }

  @override
  Future<WhatsappResponse> getStatusInstanceWhatsapp() async {
    try {
      await _whatsappClient.get('/whatsapp/evolution/get-status-instance');

      return WhatsappResponse(
        success: true,
        message: 'Estado obtenido correctamente',
      );
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      return WhatsappResponse(
        success: false,
        message: 'Error al obtener estado: $e',
      );
    } catch (e) {
      return WhatsappResponse(
        success: false,
        message: 'Error al obtener estado: $e',
      );
    }
  }

  @override
  Future<WhatsappResponse> connectInstance() async {
    try {
      await _whatsappClient.get(
        '/whatsapp/evolution/connet-instance',
        options: Options(headers: _headersWithHideLoader),
      );

      return WhatsappResponse(
        success: true,
        message: 'Instancia conectada correctamente',
      );
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      return WhatsappResponse(
        success: false,
        message: 'Error al conectar instancia: $e',
      );
    } catch (e) {
      return WhatsappResponse(
        success: false,
        message: 'Error al conectar instancia: $e',
      );
    }
  }

  @override
  Future<WhatsappResponse> disconnectInstance() async {
    try {
      await _whatsappClient.delete(
        '/whatsapp/evolution/disconnet-instance',
        options: Options(headers: _headersWithHideLoader),
      );

      return WhatsappResponse(
        success: true,
        message: 'Instancia desconectada correctamente',
      );
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      return WhatsappResponse(
        success: false,
        message: 'Error al desconectar instancia: $e',
      );
    } catch (e) {
      return WhatsappResponse(
        success: false,
        message: 'Error al desconectar instancia: $e',
      );
    }
  }

  @override
  Future<WhatsappResponse> createInstanceWhatsapp(String body) async {
    try {
      await _whatsappClient.post(
        '/whatsapp/evolution/create-instance',
        data: body,
      );

      return WhatsappResponse(
        success: true,
        message: 'Instancia creada correctamente',
      );
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      return WhatsappResponse(
        success: false,
        message: 'Error al crear instancia: $e',
      );
    } catch (e) {
      return WhatsappResponse(
        success: false,
        message: 'Error al crear instancia: $e',
      );
    }
  }

  @override
  Future<WhatsappResponse> deleteInstance() async {
    try {
      await _whatsappClient.delete('/whatsapp/evolution/delete-instance');

      return WhatsappResponse(
        success: true,
        message: 'Instancia eliminada correctamente',
      );
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      return WhatsappResponse(
        success: false,
        message: 'Error al eliminar instancia: $e',
      );
    } catch (e) {
      return WhatsappResponse(
        success: false,
        message: 'Error al eliminar instancia: $e',
      );
    }
  }
}