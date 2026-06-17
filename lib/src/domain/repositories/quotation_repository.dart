import 'package:teki_app/src/data/models/teki_model/quotation.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';

abstract class QuotationRepository {
  /// Crea una cotización
  Future<Ticket> createQuotation(Ticket ticket);

  /// Obtiene el siguiente número de cotización según tipoDocumento y serie
  Future<int> getNextQuotationNumber(String tipoDocumento, String serie);

  /// Obtiene una cotización por id, con su modelo propio (no Ticket)
  Future<Quotation> getQuotationById(int id);

  /// Lista paginada de cotizaciones según filtros
  Future<List<Quotation>> getQuotations(Map<String, dynamic> params);
}
