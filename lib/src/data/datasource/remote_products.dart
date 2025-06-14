import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/teki_model/currency.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/response/products.dart';
import 'package:teki_app/src/domain/datasource/products_datasource.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import 'package:teki_app/src/utils/notifications.dart';

class RemoteProducts extends ProductsDatasource {
  Dio dio = ApiClient.dio;
  @override
  Future<Product> getProductById(int id) async{
    try {
      final response = await dio.get('/products/$id');
      return Product.fromJson(response.data);
    } on DioException catch (e) {
      String errorMessage = 'Error de conexión';
      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? 'Error de conexión';
      } else {
        errorMessage = e.message ?? 'Error de conexión';
      }
      return Future.error(errorMessage);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  @override
  Future<ProductResponse> getProducts(Map<String, dynamic> params) async {
    try {
      final response = await dio.get('/products', queryParameters: params);
      return ProductResponse.fromJson(response.data);
    } on DioException catch (e) {
      String errorMessage = 'Error de conexión';

      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? 'Error de conexión';
      } else {
        errorMessage = e.message ?? 'Error de conexión';
      }
      errorNotification(errorMessage);

      return ProductResponse(
        content: [],
        empty: true,
        first: true,
        last: false,
        number: 0,
        pageable: null,
        size: 0,
        sort: null,
        totalElements: 0,
        totalPages: 0,
      );
    } catch (e) {
      errorNotification(e.toString());
      return ProductResponse(
        content: [],
        empty: true,
        first: true,
        last: false,
        number: 0,
        pageable: null,
        size: 0,
        sort: null,
        totalElements: 0,
        totalPages: 0,
      );
    }
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
  Future<List<Product>> searchProducts(String query) {
    // TODO: implement searchProducts
    throw UnimplementedError();
  }

  @override
  Future<List<Currency>> getCurrency() async {
    try {
      final response = await dio.get('/currencies');
      List<Currency> currencies = (response.data as List)
          .map((currency) => Currency.fromJson(currency))
          .toList();
      return currencies;
    } catch (e) {
      return Future.error(e.toString());
    }
    // TODO: implement getCurrency
    throw UnimplementedError();
  }
  
  @override
  Future<Product> createProduct(Product product) async{
    try {
      final response = await dio.post('/products', data: product.toJson());
      return Product.fromJson(response.data);
    } catch (e) {
      return Future.error(e.toString());
    }
  }
  
  @override
  Future<Product> updateProduct(Product product) async{
    try {
      final response = await dio.put('/products', data: product.toJson());
      return Product.fromJson(response.data);
    } catch (e) {
      return Future.error(e.toString());
    }
  }
}
