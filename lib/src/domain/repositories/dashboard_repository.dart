import 'package:teki_app/src/data/models/teki_model/total_counter.dart';

abstract class DashboardRepository {
  Future<TotalCounter> getSalesCount(int idPuntoVenta);
  Future<TotalCounter> getCustomerCount();

  /// ✅ Nuevo método para obtener montos agrupados por moneda
  Future<List<Map<String, dynamic>>> getAmountsByCurrency(
      Map<String, dynamic> params);
}
