import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/whatsapp/data_send.dart';
import 'package:teki_app/src/utils/contstants.dart';

class WhatsappHelper {
  /// Genera la URL del PDF 
  static String getUrlPdf(Ticket ticket, String size) {
    final baseUrl = Environment.apiUrl;
    return '$baseUrl/public/pdf/tickets/${ticket.uuid}/${ticket.identificadorDocumento}?tipo=$size';
  }

  /// Transforma el tipo de comprobante a texto legible
  static String transformTipoComprobante(String? value) {
    switch (value) {
      case '01':
        return 'Factura';
      case '03':
        return 'Boleta';
      case 'NV':
        return 'Nota de venta';
      case '07':
        return 'Nota de crédito';
      case '08':
        return 'Nota de débito';
      case '09':
        return 'Guía de remisión electrónica';
      case 'GM':
        return 'Guía de remisión manual';
      case 'CO':
        return 'Cotización';
      default:
        return '';
    }
  }

  /// Genera el texto del email desde el ticket siguiendo la lógica exacta de Angular
  static String getTextEmailFromTicket(Ticket ticket) {
    final denominacion = ticket.denominacionReceptor ?? 'Cliente';
    final tipoComprobante = transformTipoComprobante(ticket.tipoComprobante);
    final serie = ticket.serie ?? '';
    final numero = ticket.numero?.toString() ?? '';
    
    return '''<h2>Comprobante Electrónico.</h2><br>
    <p>Estimado:&nbsp;&nbsp;<strong>$denominacion</strong>&nbsp;&nbsp;</p>
    <p>se&nbsp;<strong>adjunta</strong>&nbsp;el comprobante electrónico&nbsp;
    <strong>"$tipoComprobante"</strong>&nbsp;de Serie: $serie y
    &nbsp;Número: $numero;&nbsp;en formato&nbsp;<strong>PDF</strong>&nbsp;y&nbsp;
    <strong>XML</strong>.</p><p><br></p>''';
    }

  /// Genera el DataSend 
  static DataSend getDataSend(Ticket ticket, String nombreComercialEmpresa) {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final url = '${getUrlPdf(ticket, 'A4')}&time=$currentTime';
    final serie = ticket.serie ?? '';
    final numero = ticket.numero?.toString() ?? '';
    final nombreComercialSafe = nombreComercialEmpresa.replaceAll('&', 'Y');

    return DataSend(
      id: ticket.id,
      nameMessage: '$serie-$numero-$currentTime',
      archivos: [],
      asunto: 'Comprobante electrónico $serie-$numero',
      emails: ticket.emailReceptor?.isNotEmpty == true 
          ? [ticket.emailReceptor!] 
          : [],
      number: ticket.telefonoReceptor,
      texto: getTextEmailFromTicket(ticket),
      url: url,
      messageWhatsappWeb: 'Hola! *$nombreComercialSafe* adjunta su comprobante electrónico con número $serie-$numero, muchas gracias por su preferencia. Link del PDF: $url',
      textMessage: 'Hola! *$nombreComercialEmpresa* adjunta su comprobante electrónico con número *$serie-$numero*, muchas gracias por su preferencia.',
      type: 'ticket',
    );
  }

  /// Valida si un número de teléfono es válido usando la regex de Angular
  static bool isValidPhoneNumber(String phoneNumber) {
    final regex = RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$');
    return regex.hasMatch(phoneNumber);
  }

  /// Formatea un número de teléfono para WhatsApp
  static String formatPhoneNumberForWhatsapp(String phoneNumber) {
    // Limpiar el número
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Si no empieza con +, agregar +51 (Perú)
    if (!cleaned.startsWith('+')) {
      if (cleaned.startsWith('51') && cleaned.length > 9) {
        cleaned = '+$cleaned';
      } else {
        cleaned = '+51$cleaned';
      }
    }
    
    return cleaned;
  }
}