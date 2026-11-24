import 'package:teki_app/src/data/datasource/remote_monthly_sales.dart';
import 'package:teki_app/src/data/models/teki_model/monthly_sales.dart';
import 'package:teki_app/src/domain/datasource/monthly_sales_datasource.dart';
import 'package:teki_app/src/domain/repositories/monthly_sales_repository.dart';

class MonthlySalesRepositoryImpl extends MonthlySalesRepository {
  final MonthlySalesRepositoryDatasource datasource;

  MonthlySalesRepositoryImpl({MonthlySalesRepositoryDatasource? datasource})
      : datasource = datasource ?? RemoteMonthlySalesDatasource();

  @override
  Future<List<MonthlySales>> getSales(int idPuntoVenta) {
    return datasource.getSales(idPuntoVenta);
  }
}
