import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/response/ticket_sale_serie_numero.dart';

abstract class TicketsSaleRepository {
  /// Busca tickets según filtros como tipo documento, fecha, cliente, etc.
  Future<List<Ticket>> searchTickets(Map<String, dynamic> params);

  /// Obtiene una lista de tickets por tipoDocumento y serie
  Future<List<Ticket>> getTicketNumeros(String tipoDocumento, String serie);

  Future<List<String>> getSeriesPorOficina(int officeId, String tipoDocumento);

  /// Obtiene el siguiente número de comprobante según tipoDocumento y serie
  Future<Ticket> getNextTicketNumber(String tipoDocumento, String serie);

  /// Crea un nuevo ticket (venta)
  Future<Ticket> createTicket(Ticket ticket);

  /// Obtiene un ticket por su ID
  Future<Ticket> getTicketById(int id);
}
