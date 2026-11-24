import 'package:teki_app/src/data/models/whatsapp/whatsapp_message_request.dart';
import 'package:teki_app/src/data/models/whatsapp/whatsapp_document_request.dart';
import 'package:teki_app/src/data/models/whatsapp/whatsapp_evolution_media_request.dart';
import 'package:teki_app/src/data/models/whatsapp/whatsapp_socket_request.dart';
import 'package:teki_app/src/data/models/whatsapp/whatsapp_response.dart';

abstract class WhatsappDataSource {
  /// Envía un mensaje de texto por WhatsApp
  Future<WhatsappResponse> sendMessage(WhatsappMessageRequest request);
  
  /// Envía un documento por WhatsApp
  Future<WhatsappResponse> sendDocument(WhatsappDocumentRequest request);
  
  /// Envía media usando Evolution API
  Future<WhatsappResponse> evolutionSendMedia(WhatsappEvolutionMediaRequest request);
  
  /// Envía mensaje usando Socket
  Future<WhatsappResponse> sendMessageSocket(WhatsappSocketRequest request);
  
  /// Cierra sesión de WhatsApp Socket
  Future<WhatsappResponse> closeSessionWhatsapp(Map<String, dynamic> data);
  
  /// Obtiene la instancia de WhatsApp Evolution
  Future<WhatsappResponse> getInstanceWhatsapp();
  
  /// Obtiene el estado de la instancia de WhatsApp Evolution
  Future<WhatsappResponse> getStatusInstanceWhatsapp();
  
  /// Conecta la instancia de WhatsApp Evolution
  Future<WhatsappResponse> connectInstance();
  
  /// Desconecta la instancia de WhatsApp Evolution
  Future<WhatsappResponse> disconnectInstance();
  
  /// Crea una instancia de WhatsApp Evolution
  Future<WhatsappResponse> createInstanceWhatsapp(String body);
  
  /// Elimina la instancia de WhatsApp Evolution
  Future<WhatsappResponse> deleteInstance();
}