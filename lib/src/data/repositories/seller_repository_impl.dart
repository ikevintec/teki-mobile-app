import 'package:teki_app/src/data/datasource/remote_sellers.dart';
import 'package:teki_app/src/data/models/teki_model/seller.dart';
import 'package:teki_app/src/domain/datasource/seller_datasource.dart';
import 'package:teki_app/src/domain/repositories/seller_repository.dart';

class SellerRepositoryImpl extends SellerRepository {
  final SellerDatasource datasource;

  SellerRepositoryImpl({SellerDatasource? datasource})
      : datasource = datasource ?? RemoteSellers();

  @override
  Future<List<Seller>> getAllSellers() {
    return datasource.getAllSellers();
  }
}
