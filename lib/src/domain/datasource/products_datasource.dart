import 'package:teki_app/src/data/models/product.dart';
import 'package:teki_app/src/data/models/response/products.dart';

abstract class ProductsDatasource {
  Future<ProductResponse> getProducts(Map<String,dynamic> params);
  Future<Product> getProductById(int id);
  Future<List<Product>> getProductsByCategory(String category);
  Future<List<Product>> getProductsByBrand(String brand);
  Future<List<Product>> searchProducts(String query);
}