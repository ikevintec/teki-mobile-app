import 'package:teki_app/src/data/models/teki_model/total_counter.dart';
import 'package:teki_app/src/domain/datasource/dashboard_datasource.dart';
import 'package:teki_app/src/domain/repositories/dashboard_repository.dart';
import 'package:teki_app/src/data/datasource/remote_dashboard.dart';

class DashboardRepositoryImpl extends DashboardRepository {
  final DashboardDatasource dashboardDatasource;

  DashboardRepositoryImpl({DashboardDatasource? dashboardDatasource})
      : dashboardDatasource =
            dashboardDatasource ?? RemoteDashboardDatasource();

  @override
  Future<TotalCounter> getSalesCount(int idPuntoVenta) {
    return dashboardDatasource.getSalesCount(idPuntoVenta);
  }

  @override
  Future<TotalCounter> getCustomerCount() {
    return dashboardDatasource.getCustomerCount();
  }

  /// ✅ Nuevo método: obtiene montos por moneda con filtros
  Future<List<Map<String, dynamic>>> getAmountsByCurrency(
      Map<String, dynamic> params) {
    return dashboardDatasource.getAmountsByCurrency(params);
  }
}
