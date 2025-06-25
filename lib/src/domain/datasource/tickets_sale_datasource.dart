import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';

abstract class TicketSaleDatasource {
  /// Obtiene el siguiente número de comprobante según tipoDocumento y serie
  Future<Ticket> getNextTicketNumber(String tipoDocumento, String serie);

  /// Crea un nuevo ticket de venta
  Future<Ticket> createTicket(Ticket ticket);

  /// Obtiene los tickets por tipoDocumento y serie
  Future<List<Ticket>> getTicketNumeros(String tipoDocumento, String serie);

  Future<List<String>> getSeriesPorOficina(int officeId, String tipoDocumento);
}
