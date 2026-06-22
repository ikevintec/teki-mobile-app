import 'package:teki_app/src/data/models/teki_model/seller.dart';

abstract class SellerRepository {
  Future<List<Seller>> getAllSellers();
}
