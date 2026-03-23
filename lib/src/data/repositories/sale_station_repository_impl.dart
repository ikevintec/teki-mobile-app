import 'package:teki_app/src/data/datasource/remote_saleStation.dart';
import 'package:teki_app/src/data/models/teki_model/saleStation.dart';
import 'package:teki_app/src/domain/datasource/sale_station.dart';
import 'package:teki_app/src/domain/repositories/sale_station_repositoy.dart';

class SaleStationRepositoryImpl extends SaleStationRepository {
  final SaleStationDataSource saleStationDataSource;

  SaleStationRepositoryImpl({SaleStationDataSource? saleStationDataSource})
      : saleStationDataSource = saleStationDataSource ?? RemoteSalestation();

  @override
  Future<List<SaleStation>> getSaleStations(int idPuntoVenta) async {
    return await saleStationDataSource.getSaleStations(idPuntoVenta);
  }
}
