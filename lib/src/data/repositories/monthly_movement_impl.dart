import 'package:teki_app/src/data/datasource/remote_monthly_movement.dart';
import 'package:teki_app/src/data/models/teki_model/monthly_movement.dart';
import 'package:teki_app/src/domain/datasource/monthly_movement_datasource.dart';
import 'package:teki_app/src/domain/repositories/monthly_movement_repository.dart';

class MovementMonthRepositoryImpl extends MovementMonthRepository {
  final MovementMonthRepositoryDatasource dataSource;

  MovementMonthRepositoryImpl({MovementMonthRepositoryDatasource? dataSource})
      : dataSource = dataSource ?? RemoteMovementMonth();

  @override
  Future<List<MonthlyMovement>> getMovementsBySalePoint(
      int idPuntoVenta) async {
    return await dataSource.getMovementsBySalePoint(idPuntoVenta);
  }
}
