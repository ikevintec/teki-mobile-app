import 'package:teki_app/src/data/models/whatsapp/whatsapp_response.dart';

abstract class WhatsappRepository {
  /// Envía un mensaje completo de WhatsApp (texto + documento)
  Future<WhatsappResponse> sendWhatsappMessage({
    required String number,
    required String message,
    required String filename,
    required String documentUrl,
  });
  
  /// Envía usando Evolution API
  Future<WhatsappResponse> sendEvolutionMedia({
    required String number,
    required String mediaUrl,
    required String caption,
    required String fileName,
  });
  
  /// Envía usando Socket
  Future<WhatsappResponse> sendSocketMessage({
    required int companyId,
    required String number,
    required String message,
    required String filename,
    required String documentUrl,
  });
  
  /// Abre WhatsApp Web (fallback)
  Future<void> openWhatsappWeb({
    required String number,
    required String message,
  });
  
  /// Valida si un número de teléfono es válido
  bool validatePhoneNumber(String phoneNumber);
  
  /// Formatea un número de teléfono
  String formatPhoneNumber(String phoneNumber);
  
  /// Cierra sesión de WhatsApp Socket
  Future<WhatsappResponse> closeSessionWhatsapp(int companyId);
  
  /// Obtiene información de instancia Evolution
  Future<WhatsappResponse> getInstanceInfo();
  
  /// Obtiene estado de instancia Evolution
  Future<WhatsappResponse> getInstanceStatus();
}