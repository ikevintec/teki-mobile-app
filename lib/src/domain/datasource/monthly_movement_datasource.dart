import 'package:teki_app/src/data/models/teki_model/monthly_movement.dart';

abstract class MovementMonthRepositoryDatasource {
  Future<List<MonthlyMovement>> getMovementsBySalePoint(int idPuntoVenta);
}
