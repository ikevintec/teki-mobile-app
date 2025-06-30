import 'package:teki_app/src/data/datasource/remote_monthlySales.dart';
import 'package:teki_app/src/data/models/teki_model/monthlySales.dart';
import 'package:teki_app/src/domain/datasource/monthlySales_datasource.dart';
import 'package:teki_app/src/domain/repositories/monthlySales_repository.dart';

class MonthlySalesRepositoryImpl extends MonthlySalesRepository {
  final MonthlySalesRepositoryDatasource datasource;

  MonthlySalesRepositoryImpl({MonthlySalesRepositoryDatasource? datasource})
      : datasource = datasource ?? RemoteMonthlySalesDatasource();

  @override
  Future<List<MonthlySales>> getSales(int idPuntoVenta) {
    return datasource.getSales(idPuntoVenta);
  }
}
