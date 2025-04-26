import 'package:teki_app/src/data/models/saleStation.dart';

abstract class SaleStationRepository {
  Future<List<SaleStation>> getSaleStations(int idPuntoVenta);
}