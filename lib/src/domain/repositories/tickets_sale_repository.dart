import 'package:teki_app/src/data/models/response/estado_sunat_response.dart';
import 'package:teki_app/src/data/models/teki_model/totalesComprobantes.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';

abstract class TicketsSaleRepository {
  /// Busca tickets según filtros como tipo documento, fecha, cliente, etc.
  Future<List<Ticket>> searchTickets(Map<String, dynamic> params);

  /// Obtiene una lista de tickets por tipoDocumento y serie
  Future<List<Ticket>> getTicketNumeros(String tipoDocumento, String serie);

  /// Obtiene las series por oficina y tipo de documento
  Future<List<String>> getSeriesPorOficina(int officeId, String tipoDocumento);

  /// Obtiene el siguiente número de comprobante según tipoDocumento y serie
  Future<int> getNextTicketNumber(String tipoDocumento, String serie);

  /// Crea un nuevo ticket (venta)
  Future<Ticket> createTicket(Ticket ticket);

  /// Actualiza un ticket existente
  Future<Ticket> updateTicket(Ticket ticket); 

  /// Obtiene un ticket por su ID
  Future<Ticket> getTicketById(int id);

  /// Consulta de comprobantes con paginación obligatoria
  Future<List<Ticket>> getComprobantes(Map<String, dynamic> params);

  Future<List<TotalesPorMoneda>> getTotalesPorMoneda(
      Map<String, dynamic> params);

  Future<EstadoSunatResponse> consultarEstadoSunat(Ticket ticket);

  /// Anula un comprobante por su identificador de documento, indicando el motivo
  Future<void> anularComprobante(String identificadorDocumento, String motivo);
}
