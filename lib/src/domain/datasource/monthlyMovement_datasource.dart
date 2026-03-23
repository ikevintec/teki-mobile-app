import 'package:teki_app/src/data/models/teki_model/monthlyMovement.dart';

abstract class MovementMonthRepositoryDatasource {
  Future<List<MonthlyMovement>> getMovementsBySalePoint(int idPuntoVenta);
}
