import 'package:teki_app/src/data/models/teki_model/saleStation.dart';

abstract class SaleStationDataSource {
  Future<List<SaleStation>> getSaleStations(int idPuntoVenta);
}