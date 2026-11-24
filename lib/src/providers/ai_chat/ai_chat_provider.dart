import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/datasource/remote_ai_chat.dart';
import 'package:teki_app/src/data/models/response/ai_chat_models.dart';
import 'package:teki_app/src/providers/config/config.dart';

/// Mensaje del chat en pantalla (usuario o asistente).
class AiChatMessage {
  final String role; // user | assistant
  final String content;
  final RespuestaIa? payload;
  final bool error;
  final int? messageId;
  final int? feedback; // 1 | -1

  const AiChatMessage({
    required this.role,
    required this.content,
    this.payload,
    this.error = false,
    this.messageId,
    this.feedback,
  });

  AiChatMessage copyWith({int? messageId, int? feedback}) => AiChatMessage(
        role: role,
        content: content,
        payload: payload,
        error: error,
        messageId: messageId ?? this.messageId,
        feedback: feedback ?? this.feedback,
      );
}

class AiChatState {
  final List<AiChatMessage> messages;
  final bool thinking;
  final String? toolStatus;
  final int? conversationId;
  final List<ConversacionIa> conversaciones;

  const AiChatState({
    this.messages = const [],
    this.thinking = false,
    this.toolStatus,
    this.conversationId,
    this.conversaciones = const [],
  });

  AiChatState copyWith({
    List<AiChatMessage>? messages,
    bool? thinking,
    String? toolStatus,
    bool clearToolStatus = false,
    int? conversationId,
    bool clearConversationId = false,
    List<ConversacionIa>? conversaciones,
  }) =>
      AiChatState(
        messages: messages ?? this.messages,
        thinking: thinking ?? this.thinking,
        toolStatus:
            clearToolStatus ? null : (toolStatus ?? this.toolStatus),
        conversationId: clearConversationId
            ? null
            : (conversationId ?? this.conversationId),
        conversaciones: conversaciones ?? this.conversaciones,
      );
}

final aiChatProvider =
    StateNotifierProvider<AiChatNotifier, AiChatState>((ref) {
  return AiChatNotifier(ref: ref, datasource: RemoteAiChat());
});

/// Mismo prompt proactivo que la web al abrir el asistente.
const kPromptResumenProactivo =
    'Salúdame por mi nombre según la hora del día y dame un breve resumen de cómo va mi negocio hoy';

class AiChatNotifier extends StateNotifier<AiChatState> {
  final Ref ref;
  final RemoteAiChat datasource;

  AiChatNotifier({required this.ref, required this.datasource})
      : super(const AiChatState());

  /// Header companyInfo, espejo de loginService.getCompanyInfo() web.
  Map<String, dynamic> get _companyInfo {
    final sesion = ref.read(sesionProvider);
    final selected = sesion.companySelected;
    final principal = sesion.login.user?.empresa;
    return {
      'id': selected?.id,
      'ruc': selected?.ruc,
      'principal': selected?.id == principal?.id && selected?.ruc == principal?.ruc,
    };
  }

  /// Al abrir el asistente: carga conversaciones y, si el chat está vacío,
  /// pide proactivamente el resumen del día (oculto y sin persistir).
  void abrir() {
    cargarConversaciones();
    if (state.messages.isEmpty && !state.thinking) {
      send(kPromptResumenProactivo, hidden: true);
    }
  }

  Future<void> cargarConversaciones() async {
    final list = await datasource.listConversations(_companyInfo);
    if (mounted) state = state.copyWith(conversaciones: list);
  }

  void nuevaConversacion() {
    state = state.copyWith(
      messages: [],
      clearConversationId: true,
    );
    send(kPromptResumenProactivo, hidden: true);
  }

  Future<void> abrirConversacion(int id) async {
    if (id == state.conversationId) return;
    final mensajes = await datasource.getConversation(id, _companyInfo);
    if (!mounted) return;
    state = state.copyWith(
      conversationId: id,
      messages: mensajes.map((m) {
        if (m.role == 'user') {
          final texto =
              m.content is Map ? (m.content['texto'] ?? '') : '${m.content}';
          return AiChatMessage(role: 'user', content: '$texto');
        }
        final r = m.content is Map
            ? RespuestaIa.fromJson(Map<String, dynamic>.from(m.content))
            : RespuestaIa(texto: '${m.content ?? ''}');
        return AiChatMessage(
          role: 'assistant',
          content: r.texto,
          payload: r,
          messageId: m.id,
        );
      }).toList(),
    );
  }

  Future<void> darFeedback(int index, int rating) async {
    final msg = state.messages[index];
    if (msg.messageId == null || msg.feedback != null) return;
    _updateMessage(index, msg.copyWith(feedback: rating));
    final ok =
        await datasource.sendFeedback(msg.messageId!, rating, _companyInfo);
    if (!ok && mounted) {
      // Revertir si el backend no lo aceptó.
      _updateMessage(index, msg);
    }
  }

  void _updateMessage(int index, AiChatMessage nuevo) {
    final list = List<AiChatMessage>.from(state.messages);
    list[index] = nuevo;
    state = state.copyWith(messages: list);
  }

  Future<void> send(String message, {bool hidden = false}) async {
    final text = message.trim();
    if (text.isEmpty || state.thinking) return;

    // En modo proactivo (hidden) no se muestra la burbuja del usuario.
    final base = List<AiChatMessage>.from(state.messages);
    if (!hidden) {
      base.add(AiChatMessage(role: 'user', content: text));
    }
    state = state.copyWith(
      messages: base,
      thinking: true,
      clearToolStatus: true,
    );

    // Historial acotado: últimos 10 turnos sin errores, sin el mensaje actual.
    final history = state.messages
        .sublist(0, hidden ? state.messages.length : state.messages.length - 1)
        .where((m) => !m.error)
        .toList();
    final acotado = history.length > 10
        ? history.sublist(history.length - 10)
        : history;

    try {
      // El resumen proactivo no se persiste, para no ensuciar el historial.
      await for (final event in datasource.chat(
        message: text,
        history: acotado
            .map((m) => {'role': m.role, 'content': m.content})
            .toList(),
        conversationId: state.conversationId,
        persist: !hidden,
        companyInfo: _companyInfo,
      )) {
        if (!mounted) return;
        _handleEvent(event);
      }
    } catch (_) {
      if (mounted) {
        state = state.copyWith(messages: [
          ...state.messages,
          const AiChatMessage(
            role: 'assistant',
            content:
                'No pude conectarme con el asistente. Inténtalo de nuevo en unos segundos.',
            error: true,
          ),
        ]);
      }
    } finally {
      if (mounted) {
        state = state.copyWith(thinking: false, clearToolStatus: true);
        cargarConversaciones();
      }
    }
  }

  void _handleEvent(AiChatEvent event) {
    switch (event.type) {
      case 'tool':
        state = state.copyWith(toolStatus: _friendlyToolName(event.name ?? ''));
        break;
      case 'respuesta':
        state = state.copyWith(
          clearToolStatus: true,
          messages: [
            ...state.messages,
            AiChatMessage(
              role: 'assistant',
              content: event.respuesta!.texto,
              payload: event.respuesta,
            ),
          ],
        );
        break;
      case 'text':
        state = state.copyWith(
          clearToolStatus: true,
          messages: [
            ...state.messages,
            AiChatMessage(role: 'assistant', content: event.content ?? ''),
          ],
        );
        break;
      case 'error':
        state = state.copyWith(
          clearToolStatus: true,
          messages: [
            ...state.messages,
            AiChatMessage(
                role: 'assistant', content: event.message ?? '', error: true),
          ],
        );
        break;
      case 'meta':
        state = state.copyWith(conversationId: event.conversationId);
        break;
      case 'saved':
        // Adjunta el id a la última respuesta del asistente (para feedback).
        for (int i = state.messages.length - 1; i >= 0; i--) {
          final m = state.messages[i];
          if (m.role == 'assistant' && m.messageId == null) {
            _updateMessage(i, m.copyWith(messageId: event.messageId));
            break;
          }
        }
        break;
    }
  }

  String _friendlyToolName(String name) {
    if (name.startsWith('ventas')) return 'Consultando tus ventas…';
    if (name.startsWith('cuentas_por_cobrar')) {
      return 'Revisando tus cuentas por cobrar…';
    }
    if (name.startsWith('cuentas_por_pagar')) {
      return 'Revisando tus cuentas por pagar…';
    }
    if (name.startsWith('caja')) return 'Consultando tu caja…';
    return 'Consultando tus datos…';
  }
}
