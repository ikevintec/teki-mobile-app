import 'package:teki_app/src/data/models/teki_model/quotation.dart';
import 'package:teki_app/src/utils/constants.dart';

/// Helper de WhatsApp exclusivo para cotizaciones. Se mantiene separado de
/// WhatsappHelper (tickets) porque la URL del PDF y los campos disponibles
/// son distintos (sin uuid/identificadorDocumento/tipoComprobante SUNAT).
class QuotationWhatsappHelper {
  static String getUrlPdf(Quotation quotation) {
    final baseUrl = Environment.apiUrl;
    return '$baseUrl/public/pdf/quotation/${quotation.id}/${quotation.serie}-${quotation.numero}';
  }

  static String getMessage(Quotation quotation, String nombreComercialEmpresa) {
    final serie = quotation.serie ?? '';
    final numero = quotation.numero?.toString() ?? '';
    return 'Hola! *$nombreComercialEmpresa* adjunta su cotización con número *$serie-$numero*, muchas gracias por su preferencia.';
  }

  static String getFilename(Quotation quotation) {
    final serie = quotation.serie ?? '';
    final numero = quotation.numero?.toString() ?? '';
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    return '$serie-$numero-$currentTime.pdf';
  }
}
