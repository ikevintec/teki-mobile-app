import 'package:teki_app/src/data/models/teki_model/monthly_sales.dart';

abstract class MonthlySalesRepositoryDatasource {
  Future<List<MonthlySales>> getSales(int idPuntoVenta);
}
