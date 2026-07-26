import 'package:teki_app/src/data/models/response/daily_sales_summary.dart';
import 'package:teki_app/src/data/models/response/top_product.dart';
import 'package:teki_app/src/data/models/teki_model/total_counter.dart';

abstract class DashboardRepository {
  Future<TotalCounter> getSalesCount(int idPuntoVenta);
  Future<TotalCounter> getCustomerCount();

  /// ✅ Nuevo método para obtener montos agrupados por moneda
  Future<List<Map<String, dynamic>>> getAmountsByCurrency(
      Map<String, dynamic> params);

  /// Ventas del día: cantidad + montos por moneda en una sola consulta.
  Future<DailySalesSummary> getTodaySalesSummary(Map<String, dynamic> params);

  /// Ranking de productos más vendidos (paridad web: /products/top-orders).
  Future<List<TopProduct>> getTopProducts(Map<String, dynamic> params);
}
