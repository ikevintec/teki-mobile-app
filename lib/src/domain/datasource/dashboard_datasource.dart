import 'package:teki_app/src/data/models/teki_model/totalCounter.dart';

abstract class DashboardDatasource {
  Future<TotalCounter> getSalesCount(int idPuntoVenta);
  Future<TotalCounter> getCustomerCount();

  /// ✅ Nuevo método para obtener montos agrupados por moneda
  Future<List<Map<String, dynamic>>> getAmountsByCurrency(
      Map<String, dynamic> params);
}
