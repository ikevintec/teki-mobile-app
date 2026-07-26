import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/response/ai_chat_models.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import 'package:teki_app/src/utils/constants.dart';

/// Cliente del servicio teki-ai. Reusa ApiClient.dio con URLs absolutas:
/// el interceptor global inyecta el Bearer token y maneja el 401.
/// El header companyInfo replica al de la web ({id, ruc, principal}).
class RemoteAiChat {
  final Dio dio = ApiClient.dio;

  String get _base => Environment.iaUrl;

  Options _options({
    required Map<String, dynamic> companyInfo,
    ResponseType? responseType,
  }) {
    return Options(
      responseType: responseType,
      headers: {'companyInfo': jsonEncode(companyInfo)},
    );
  }

  /// POST /chat con respuesta SSE. Emite los eventos conforme llegan.
  Stream<AiChatEvent> chat({
    required String message,
    required List<Map<String, String>> history,
    int? conversationId,
    bool persist = true,
    required Map<String, dynamic> companyInfo,
  }) async* {
    final response = await dio.post<ResponseBody>(
      '$_base/chat',
      data: {
        'message': message,
        'history': history,
        if (conversationId != null) 'conversationId': conversationId,
        'persist': persist,
      },
      options: _options(
        companyInfo: companyInfo,
        responseType: ResponseType.stream,
      ),
    );

    final stream = response.data?.stream;
    if (stream == null) {
      throw Exception('El asistente no respondió');
    }

    // Mismo parser de la web: eventos separados por línea en blanco,
    // con líneas "event: X" y "data: {json}".
    var buffer = '';
    await for (final chunk in stream) {
      buffer += utf8.decode(chunk, allowMalformed: true);
      int sep;
      while ((sep = buffer.indexOf('\n\n')) != -1) {
        final raw = buffer.substring(0, sep);
        buffer = buffer.substring(sep + 2);
        final event = _parseSseEvent(raw);
        if (event != null) yield event;
      }
    }
  }

  AiChatEvent? _parseSseEvent(String raw) {
    var eventName = '';
    var data = '';
    for (final line in raw.split('\n')) {
      if (line.startsWith('event: ')) {
        eventName = line.substring(7).trim();
      } else if (line.startsWith('data: ')) {
        data = line.substring(6);
      }
    }
    if (eventName.isEmpty || eventName == 'done' || data.isEmpty) return null;
    try {
      final obj = jsonDecode(data) as Map<String, dynamic>;
      if (obj['type'] != null) return AiChatEvent.fromJson(obj);
      // Eventos sin 'type' en el data: se resuelve por el nombre del evento.
      if (eventName == 'meta') {
        return AiChatEvent.fromJson(
            {'type': 'meta', 'conversationId': obj['conversationId']});
      }
      if (eventName == 'saved') {
        return AiChatEvent.fromJson(
            {'type': 'saved', 'messageId': obj['messageId']});
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<ConversacionIa>> listConversations(
      Map<String, dynamic> companyInfo) async {
    try {
      final response = await dio.get(
        '$_base/conversations',
        options: _options(companyInfo: companyInfo),
      );
      return ((response.data?['conversaciones'] as List?) ?? [])
          .map((e) => ConversacionIa.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<MensajeGuardadoIa>> getConversation(
      int id, Map<String, dynamic> companyInfo) async {
    try {
      final response = await dio.get(
        '$_base/conversations/$id',
        options: _options(companyInfo: companyInfo),
      );
      return ((response.data?['mensajes'] as List?) ?? [])
          .map((e) => MensajeGuardadoIa.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> sendFeedback(
      int messageId, int rating, Map<String, dynamic> companyInfo) async {
    try {
      final response = await dio.post(
        '$_base/conversations/feedback',
        data: {'messageId': messageId, 'rating': rating},
        options: _options(companyInfo: companyInfo),
      );
      return response.data?['ok'] == true;
    } catch (_) {
      return false;
    }
  }
}
