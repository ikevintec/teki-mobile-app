import 'package:teki_app/src/data/datasource/remote_whatsapp_datasource.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:teki_app/src/domain/datasource/whatsapp_datasource.dart';
import 'package:teki_app/src/data/models/whatsapp/whatsapp_message_request.dart';
import 'package:teki_app/src/data/models/whatsapp/whatsapp_document_request.dart';
import 'package:teki_app/src/data/models/whatsapp/whatsapp_evolution_media_request.dart';
import 'package:teki_app/src/data/models/whatsapp/whatsapp_socket_request.dart';
import 'package:teki_app/src/data/models/whatsapp/whatsapp_response.dart';
import 'package:teki_app/src/domain/repositories/whatsapp_repository.dart';

class WhatsappRepositoryImpl implements WhatsappRepository {
  final WhatsappDataSource dataSource;

  WhatsappRepositoryImpl({WhatsappDataSource? dataSource})
      : dataSource = dataSource ?? WhatsappDataSourceImpl();

  @override
  Future<WhatsappResponse> sendWhatsappMessage({
    required String number,
    required String message,
    required String filename,
    required String documentUrl,
  }) async {
    try {
      final formattedNumber = formatPhoneNumber(number);
      
      // Enviar mensaje de texto
      final messageResponse = await dataSource.sendMessage(
        WhatsappMessageRequest(
          number: formattedNumber,
          message: message,
        ),
      );

      if (!messageResponse.success) {
        return messageResponse;
      }

      // Enviar documento
      final documentResponse = await dataSource.sendDocument(
        WhatsappDocumentRequest(
          number: formattedNumber,
          filename: '$filename.pdf',
          document: documentUrl,
        ),
      );

      return documentResponse;
    } catch (e) {
      return WhatsappResponse(
        success: false,
        message: 'Error al enviar mensaje completo: $e',
      );
    }
  }

  @override
  Future<WhatsappResponse> sendEvolutionMedia({
    required String number,
    required String mediaUrl,
    required String caption,
    required String fileName,
  }) async {
    try {
      final formattedNumber = formatPhoneNumber(number);
      final evolutionNumber = formattedNumber.contains('+') 
          ? formattedNumber 
          : '+51$formattedNumber';

      final request = WhatsappEvolutionMediaRequest(
        number: evolutionNumber,
        media: mediaUrl,
        caption: caption,
        fileName: fileName,
        mediatype: 'document',
      );

      return await dataSource.evolutionSendMedia(request);
    } catch (e) {
      return WhatsappResponse(
        success: false,
        message: 'Error al enviar por Evolution: $e',
      );
    }
  }

  @override
  Future<WhatsappResponse> sendSocketMessage({
    required int companyId,
    required String number,
    required String message,
    required String filename,
    required String documentUrl,
  }) async {
    try {
      final formattedNumber = formatPhoneNumber(number);
      
      final request = WhatsappSocketRequest(
        event: 'sendMessageWhatsapp',
        idCompany: companyId,
        number: formattedNumber,
        message: message,
        file: '$filename.pdf',
        url: documentUrl,
      );

      return await dataSource.sendMessageSocket(request);
    } catch (e) {
      return WhatsappResponse(
        success: false,
        message: 'Error al enviar por Socket: $e',
      );
    }
  }

  @override
  Future<void> openWhatsappWeb({
    required String number,
    required String message,
  }) async {
    try {
      final formattedNumber = formatPhoneNumber(number);
      final encodedMessage = Uri.encodeComponent(message);
      final url = 'https://api.whatsapp.com/send?phone=$formattedNumber&text=$encodedMessage';
      
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('No se pudo abrir WhatsApp Web');
      }
    } catch (e) {
      throw Exception('Error al abrir WhatsApp Web: $e');
    }
  }

  @override
  bool validatePhoneNumber(String phoneNumber) {
    // Expresión regular para validar números de teléfono
    final regex = RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$');
    return regex.hasMatch(phoneNumber);
  }

  @override
  String formatPhoneNumber(String phoneNumber) {
    // Remover todos los caracteres no numéricos excepto el +
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Si no tiene código de país, agregar +51 (Perú)
    if (!cleaned.startsWith('+')) {
      if (cleaned.startsWith('51')) {
        cleaned = '+$cleaned';
      } else {
        cleaned = '+51$cleaned';
      }
    }
    
    return cleaned;
  }

  @override
  Future<WhatsappResponse> closeSessionWhatsapp(int companyId) async {
    try {
      final data = {
        'event': 'disconectFromWeb',
        'idCompany': companyId,
      };
      
      return await dataSource.closeSessionWhatsapp(data);
    } catch (e) {
      return WhatsappResponse(
        success: false,
        message: 'Error al cerrar sesión: $e',
      );
    }
  }

  @override
  Future<WhatsappResponse> getInstanceInfo() async {
    try {
      return await dataSource.getInstanceWhatsapp();
    } catch (e) {
      return WhatsappResponse(
        success: false,
        message: 'Error al obtener información de instancia: $e',
      );
    }
  }

  @override
  Future<WhatsappResponse> getInstanceStatus() async {
    try {
      return await dataSource.getStatusInstanceWhatsapp();
    } catch (e) {
      return WhatsappResponse(
        success: false,
        message: 'Error al obtener estado de instancia: $e',
      );
    }
  }
}