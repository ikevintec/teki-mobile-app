import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/totalesFormaPagos.dart';

abstract class TicketSaleDatasource {
  /// Obtiene el siguiente número de comprobante según tipoDocumento y serie
  Future<Ticket> getNextTicketNumber(String tipoDocumento, String serie);

  /// Crea un nuevo ticket de venta
  Future<Ticket> createTicket(Ticket ticket);

  /// Obtiene los tickets por tipoDocumento y serie
  Future<List<Ticket>> getTicketNumeros(String tipoDocumento, String serie);

  Future<List<String>> getSeriesPorOficina(int officeId, String tipoDocumento);
  Future<List<Ticket>> getComprobantes({
    required String filtroDesde,
    required String filtroHasta,
    required String rucEmisor,
    required int idPuntoVenta,
    required int idVendedor,
    required int page,
    required int size,
  });

  /// Obtiene los totales agrupados por forma de pago
  Future<List<PaymentMethodTotal>> getTotalesPorFormaPago({
    required String filtroDesde,
    required String filtroHasta,
    required String filtroRucEmisor,
    required int idPuntoVenta,
    required int idVendedor,
  });
}
