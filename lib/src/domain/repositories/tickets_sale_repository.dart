import 'package:teki_app/src/data/models/teki_model/totalesComprobantes.dart';
import 'package:teki_app/src/data/models/teki_model/totalesFormaPagos.dart';

import 'package:teki_app/src/data/models/teki_model/ticket.dart';

abstract class TicketsSaleRepository {
  /// Busca tickets según filtros como tipo documento, fecha, cliente, etc.
  Future<List<Ticket>> searchTickets(Map<String, dynamic> params);

  /// Obtiene una lista de tickets por tipoDocumento y serie
  Future<List<Ticket>> getTicketNumeros(String tipoDocumento, String serie);

  /// Obtiene las series por oficina y tipo de documento
  Future<List<String>> getSeriesPorOficina(int officeId, String tipoDocumento);

  /// Obtiene el siguiente número de comprobante según tipoDocumento y serie
  Future<Ticket> getNextTicketNumber(String tipoDocumento, String serie);

  /// Crea un nuevo ticket (venta)
  Future<Ticket> createTicket(Ticket ticket);

  /// Obtiene un ticket por su ID
  Future<Ticket> getTicketById(int id);

  /// Consulta de comprobantes con paginación obligatoria
  Future<List<Ticket>> getComprobantes(Map<String, dynamic> params);

  /// Obtiene los totales agrupados por forma de pago
  Future<List<PaymentMethodTotal>> getTotalesPorFormaPago({
    required String filtroDesde,
    required String filtroHasta,
    required String filtroRucEmisor,
    required int idPuntoVenta,
    required int idVendedor,
  });

  Future<List<TotalesPorMoneda>> getTotalesPorMoneda({
    required String filtroDesde,
    required String filtroHasta,
    required String filtroRucEmisor,
    required int idPuntoVenta,
    required int idVendedor,
  });
}
