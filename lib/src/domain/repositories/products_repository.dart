import 'package:teki_app/src/data/models/teki_model/currency.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/response/products.dart';

abstract class ProductsRepository {
  Future<ProductResponse> getProducts(Map<String, dynamic> params);
  Future<List<Product>> searchProducts(Map<String, dynamic> params);
  Future<List<Product>> getFlatProducts();
  Future<Product> getProductById(int id);
  Future<List<Currency>> getCurrency();
  Future<Product> createProduct(Product product);
  Future<Product> updateProduct(Product product);
  Future<List<Product>> getProductsByCategory(String category);
  Future<List<Product>> getProductsByBrand(String brand);
}
