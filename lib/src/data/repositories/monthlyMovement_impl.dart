import 'package:teki_app/src/data/datasource/remote_monthlyMovement.dart';
import 'package:teki_app/src/data/models/teki_model/monthlyMovement.dart';
import 'package:teki_app/src/domain/datasource/monthlyMovement_datasource.dart';
import 'package:teki_app/src/domain/repositories/monthlyMovement_repository.dart';

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
