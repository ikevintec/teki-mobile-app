import 'package:teki_app/src/data/datasource/remote_products.dart';
import 'package:teki_app/src/data/models/teki_model/currency.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/response/products.dart';
import 'package:teki_app/src/domain/datasource/products_datasource.dart';
import 'package:teki_app/src/domain/repositories/products_repository.dart';

class ProductsRepositoryImpl extends ProductsRepository {
  final ProductsDatasource productsDatasource;

  ProductsRepositoryImpl({ProductsDatasource? productsDatasource})
      : productsDatasource = productsDatasource ?? RemoteProducts();

  @override
  Future<ProductResponse> getProducts(Map<String,dynamic> params) async{
    return await productsDatasource.getProducts(params);
  }

  @override
  Future<List<Product>> searchProducts(Map<String, dynamic> params) async {
    return await productsDatasource.searchProducts(params);
  }

  @override
  Future<String> getFlatProductsRaw() async {
    return await productsDatasource.getFlatProductsRaw();
  }

  @override
  Future<Product> getProductById(int id) async{
    return productsDatasource.getProductById(id);
  }

  @override
  Future<List<Product>> getProductsByBrand(String brand) {
    // TODO: implement getProductsByBrand
    throw UnimplementedError();
  }

  @override
  Future<List<Product>> getProductsByCategory(String category) {
    // TODO: implement getProductsByCategory
    throw UnimplementedError();
  }

  @override
  Future<List<Currency>> getCurrency() async {
    return await productsDatasource.getCurrency();
  }
  
  @override
  Future<Product> createProduct(Product product) async{
    return productsDatasource.createProduct(product);
  }
  
  @override
  Future<Product> updateProduct(Product product) async{
    return productsDatasource.updateProduct(product);
  }

}
