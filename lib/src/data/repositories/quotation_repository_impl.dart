import 'package:teki_app/src/data/datasource/remote_quotation_datasource.dart';
import 'package:teki_app/src/data/models/teki_model/quotation.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/domain/datasource/quotation_datasource.dart';
import 'package:teki_app/src/domain/repositories/quotation_repository.dart';

class QuotationRepositoryImpl extends QuotationRepository {
  final QuotationDatasource datasource;

  /// Permite inyectar un datasource, por defecto usa RemoteQuotationDatasource con Dio
  QuotationRepositoryImpl({QuotationDatasource? datasource})
      : datasource = datasource ?? RemoteQuotationDatasource();

  @override
  Future<Ticket> createQuotation(Ticket ticket) {
    return datasource.createQuotation(ticket);
  }

  @override
  Future<Ticket> updateQuotation(Ticket ticket) {
    return datasource.updateQuotation(ticket);
  }

  @override
  Future<int> getNextQuotationNumber(String tipoDocumento, String serie) {
    return datasource.getNextQuotationNumber(tipoDocumento, serie);
  }

  @override
  Future<Quotation> getQuotationById(int id) {
    return datasource.getQuotationById(id);
  }

  @override
  Future<List<Quotation>> getQuotations(Map<String, dynamic> params) {
    return datasource.getQuotations(params);
  }

  @override
  Future<void> deleteQuotation(int id) {
    return datasource.deleteQuotation(id);
  }
}
