import 'package:teki_app/src/data/datasource/remote_purchases.dart';
import 'package:teki_app/src/data/models/response/purchase_response.dart';
import 'package:teki_app/src/data/models/teki_model/purchase.dart';
import 'package:teki_app/src/data/models/teki_model/supplier.dart';
import 'package:teki_app/src/domain/datasource/purchases_datasource.dart';
import 'package:teki_app/src/domain/repositories/purchases_repository.dart';

class PurchasesRepositoryImpl extends PurchasesRepository {
  final PurchasesDatasource datasource;

  PurchasesRepositoryImpl({PurchasesDatasource? datasource})
      : datasource = datasource ?? RemotePurchases();

  @override
  Future<PurchaseResponse> getPurchases(Map<String, dynamic> params) =>
      datasource.getPurchases(params);

  @override
  Future<Purchase> savePurchase(Purchase purchase) =>
      datasource.savePurchase(purchase);

  @override
  Future<void> cancelPurchase(int id, String motivo) =>
      datasource.cancelPurchase(id, motivo);

  @override
  Future<List<Supplier>> searchSuppliers(String query) =>
      datasource.searchSuppliers(query);
}
