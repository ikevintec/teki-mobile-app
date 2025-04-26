import 'package:teki_app/src/data/models/saleStation.dart';

abstract class SaleStationDataSource {
  Future<List<SaleStation>> getSaleStations(int idPuntoVenta);
}