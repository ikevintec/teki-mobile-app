import 'package:teki_app/src/data/models/response/purchase_response.dart';
import 'package:teki_app/src/data/models/teki_model/purchase.dart';
import 'package:teki_app/src/data/models/teki_model/supplier.dart';

abstract class PurchasesDatasource {
  Future<PurchaseResponse> getPurchases(Map<String, dynamic> params);
  Future<Purchase> savePurchase(Purchase purchase);
  Future<void> cancelPurchase(int id, String motivo);
  Future<List<Supplier>> searchSuppliers(String query);
}
