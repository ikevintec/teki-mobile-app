import 'package:teki_app/src/data/models/response/estado_sunat_response.dart';
import 'package:teki_app/src/data/models/teki_model/totalesComprobantes.dart';

import 'package:teki_app/src/domain/datasource/tickets_sale_datasource.dart';
import 'package:teki_app/src/data/datasource/remote_ticket_sale.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/domain/repositories/tickets_sale_repository.dart';

class TicketSaleRepositoryImpl extends TicketsSaleRepository {
  final TicketSaleDatasource datasource;

  /// Permite inyectar un datasource, por defecto usa RemoteTicketSaleDatasource con Dio
  TicketSaleRepositoryImpl({TicketSaleDatasource? datasource})
      : datasource = datasource ?? RemoteTicketSaleDatasource();

  @override
  Future<int> getNextTicketNumber(String tipoDocumento, String serie) {
    return datasource.getNextTicketNumber(tipoDocumento, serie);
  }

  @override
  Future<List<String>> getSeriesPorOficina(int officeId, String tipoDocumento) {
    return datasource.getSeriesPorOficina(officeId, tipoDocumento);
  }

  @override
  Future<Ticket> createTicket(Ticket ticket) {
    return datasource.createTicket(ticket);
  }

  @override
  Future<List<Ticket>> getTicketNumeros(String tipoDocumento, String serie) {
    return datasource.getTicketNumeros(tipoDocumento, serie);
  }

  @override
  Future<Ticket> getTicketById(int id) {
    return datasource.getTicketById(id);
  }

  @override
  Future<List<Ticket>> searchTickets(Map<String, dynamic> params) {
    throw UnimplementedError(); // Implementar cuando lo necesites
  }

  @override
  Future<List<Ticket>> getComprobantes(Map<String, dynamic> params) {
    return datasource.getComprobantes(params);
  }

  @override
  Future<List<TotalesPorMoneda>> getTotalesPorMoneda(
      Map<String, dynamic> params) {
    return datasource.getTotalesPorMoneda(params);
  }
  
  @override
  Future<Ticket> updateTicket(Ticket ticket) {
    return datasource.updateTicket(ticket);
  }

  @override
  Future<EstadoSunatResponse> consultarEstadoSunat(Ticket ticket) {
    return datasource.consultarEstadoSunat(ticket);
  }

  @override
  Future<void> anularComprobante(String identificadorDocumento, String motivo) {
    return datasource.anularComprobante(identificadorDocumento, motivo);
  }
}
