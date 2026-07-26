import 'package:teki_app/src/data/models/response/estado_sunat_response.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/totales_comprobantes.dart';
import 'package:teki_app/src/data/models/teki_model/totales_forma_pagos.dart';

abstract class TicketSaleDatasource {
  /// Obtiene el siguiente número de comprobante según tipoDocumento y serie
  Future<int> getNextTicketNumber(String tipoDocumento, String serie);

  /// Crea un nuevo ticket de venta
  Future<Ticket> createTicket(Ticket ticket);

  /// Actualiza un ticket existente
  Future<Ticket> updateTicket(Ticket ticket);

  /// Obtiene los tickets por tipoDocumento y serie
  Future<List<Ticket>> getTicketNumeros(String tipoDocumento, String serie);

  Future<List<String>> getSeriesPorOficina(int officeId, String tipoDocumento);
  Future<List<Ticket>> getComprobantes(Map<String, dynamic> params);

  Future<List<TotalesPorMoneda>> getTotalesPorMoneda(Map<String, dynamic> params);

  Future<List<TotalVentasFormaPago>> getTotalesFormaPago(Map<String, dynamic> params);

  Future<Ticket> getTicketById(int id);

  Future<EstadoSunatResponse> consultarEstadoSunat(Ticket ticket);

  /// Anula un comprobante por su identificador de documento, indicando el motivo
  Future<void> anularComprobante(String identificadorDocumento, String motivo);
}
