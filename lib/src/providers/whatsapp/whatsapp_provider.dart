import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/repositories/whatsapp_repository_impl.dart';
import 'package:teki_app/src/data/models/whatsapp/whatsapp_response.dart';
import 'package:teki_app/src/data/models/teki_model/config.dart';
import 'package:teki_app/src/domain/repositories/whatsapp_repository.dart';
import 'package:teki_app/src/providers/config/config.dart';


final whatsappProvider = StateNotifierProvider<WhatsappNotifier, WhatsappState>((ref) {
  final WhatsappRepository whatsappRepository = WhatsappRepositoryImpl();
  final sesion = ref.watch(sesionProvider);
  return WhatsappNotifier(repository: whatsappRepository, sesion: sesion);
});

class WhatsappState {
  final bool isLoading;
  final String? error;
  final bool lastOperationSuccess;
  final String? lastMessage;

  const WhatsappState({
    this.isLoading = false,
    this.error,
    this.lastOperationSuccess = false,
    this.lastMessage,
  });

  WhatsappState copyWith({
    bool? isLoading,
    String? error,
    bool? lastOperationSuccess,
    String? lastMessage,
  }) {
    return WhatsappState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastOperationSuccess: lastOperationSuccess ?? this.lastOperationSuccess,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}

class WhatsappNotifier extends StateNotifier<WhatsappState> {
  final WhatsappRepository repository;
  final SesionState sesion;

  WhatsappNotifier({
    required this.repository,
    required this.sesion,
  }) : super(const WhatsappState());

  /// Método principal para enviar WhatsApp siguiendo la lógica del código TypeScript
  Future<WhatsappResponse> sendWhatsapp({
    required String phoneNumber,
    required String message,
    required String filename,
    required String documentUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Validar número de teléfono
      if (!repository.validatePhoneNumber(phoneNumber)) {
        final errorResponse = WhatsappResponse(
          success: false,
          message: 'Número de teléfono inválido.',
        );
        _updateStateFromResponse(errorResponse);
        return errorResponse;
      }

      final config = sesion.config;
      if (config == null) {
        final errorResponse = WhatsappResponse(
          success: false,
          message: 'Configuración no disponible.',
        );
        _updateStateFromResponse(errorResponse);
        return errorResponse;
      }

      // Si usa API de WhatsApp
      if (config.usaWhatsappApi ?? false) {
        return await _sendWithApi(
          phoneNumber: phoneNumber,
          message: message,
          filename: filename,
          documentUrl: documentUrl,
          config: config,
        );
      } else {
        // Fallback a WhatsApp Web
        await repository.openWhatsappWeb(
          number: phoneNumber,
          message: message,
        );
        
        final successResponse = WhatsappResponse(
          success: true,
          message: 'Abriendo WhatsApp Web...',
        );
        _updateStateFromResponse(successResponse);
        return successResponse;
      }
    } catch (e) {
      final errorResponse = WhatsappResponse(
        success: false,
        message: 'Error inesperado: $e',
      );
      _updateStateFromResponse(errorResponse);
      return errorResponse;
    }
  }

  Future<WhatsappResponse> _sendWithApi({
    required String phoneNumber,
    required String message,
    required String filename,
    required String documentUrl,
    required ConfigCompany config,
  }) async {
    // Función para enviar por Cloud Message (fallback)
    Future<WhatsappResponse> sendByCloudMessage() async {
      return await repository.sendWhatsappMessage(
        number: phoneNumber,
        message: message,
        filename: filename,
        documentUrl: documentUrl,
      );
    }

    // Si es tipo Evolution
    if (config.tipoClienteWhatsapp == 'EVOLUTION') {
      try {
        final response = await repository.sendEvolutionMedia(
          number: phoneNumber,
          mediaUrl: documentUrl,
          caption: message,
          fileName: filename,
        );

        if (response.success) {
          _updateStateFromResponse(response);
          return response;
        } else {
          // Si falla Evolution, usar Cloud Message como fallback
          debugPrint('Error al enviar mensaje por Evolution, usando fallback');
          final fallbackResponse = await sendByCloudMessage();
          _updateStateFromResponse(fallbackResponse);
          return fallbackResponse;
        }
      } catch (e) {
        debugPrint('Error en Evolution: $e, usando fallback');
        final fallbackResponse = await sendByCloudMessage();
        _updateStateFromResponse(fallbackResponse);
        return fallbackResponse;
      }
    }
    // Si es tipo Socket
    else if (config.tipoClienteWhatsapp == 'SOCKET') {
      try {
        final response = await repository.sendSocketMessage(
          companyId: sesion.company?.id ?? 0,
          number: phoneNumber,
          message: message,
          filename: filename,
          documentUrl: documentUrl,
        );

        if (response.success) {
          _updateStateFromResponse(response);
          return response;
        } else {
          // Si falla Socket, cerrar sesión y usar fallback
          debugPrint('Error al enviar mensaje por socket, cerrando sesión');
          await repository.closeSessionWhatsapp(sesion.company?.id ?? 0);
          final fallbackResponse = await sendByCloudMessage();
          _updateStateFromResponse(fallbackResponse);
          return fallbackResponse;
        }
      } catch (e) {
        debugPrint('Error en Socket: $e, usando fallback');
        await repository.closeSessionWhatsapp(sesion.company?.id ?? 0);
        final fallbackResponse = await sendByCloudMessage();
        _updateStateFromResponse(fallbackResponse);
        return fallbackResponse;
      }
    }
    // Fallback por defecto
    else {
      final response = await sendByCloudMessage();
      _updateStateFromResponse(response);
      return response;
    }
  }

  void _updateStateFromResponse(WhatsappResponse response) {
    state = state.copyWith(
      isLoading: false,
      lastOperationSuccess: response.success,
      lastMessage: response.message,
      error: response.success ? null : response.message,
    );
  }

  /// Limpiar estado
  void clearState() {
    state = const WhatsappState();
  }

  /// Validar número de teléfono
  bool validatePhone(String phoneNumber) {
    return repository.validatePhoneNumber(phoneNumber);
  }

  /// Formatear número de teléfono
  String formatPhone(String phoneNumber) {
    return repository.formatPhoneNumber(phoneNumber);
  }
}