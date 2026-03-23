import 'package:teki_app/src/data/models/teki_model/monthlyMovement.dart';

abstract class MovementMonthRepository {
  Future<List<MonthlyMovement>> getMovementsBySalePoint(int idPuntoVenta);
}
