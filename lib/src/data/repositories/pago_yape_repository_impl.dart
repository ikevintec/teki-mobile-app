import 'package:teki_app/src/data/datasource/remote_pago_yape.dart';
import 'package:teki_app/src/data/models/yape/pago_yape.dart';
import 'package:teki_app/src/domain/datasource/pago_yape_datasource.dart';
import 'package:teki_app/src/domain/repositories/pago_yape_repository.dart';

class PagoYapeRepositoryImpl extends PagoYapeRepository {
  final PagoYapeDatasource datasource;

  PagoYapeRepositoryImpl({PagoYapeDatasource? datasource})
    : datasource = datasource ?? RemotePagoYape();

  @override
  Future<PagoYapePage> getPagos({required int pageNumber, int perPage = 20}) {
    return datasource.getPagos(pageNumber: pageNumber, perPage: perPage);
  }
}
