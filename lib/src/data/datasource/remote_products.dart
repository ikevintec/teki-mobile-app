
import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/product.dart';
import 'package:teki_app/src/data/models/response/products.dart';
import 'package:teki_app/src/domain/datasource/products_datasource.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import 'package:teki_app/src/utils/notifications.dart';

class RemoteProducts extends ProductsDatasource {
  Dio dio = ApiClient.dio;
  @override
  Future<Product> getProductById(int id) {
    // TODO: implement getProductById
    throw UnimplementedError();
  }

  @override
  Future<ProductResponse> getProducts(Map<String,dynamic> params) async {
    try {
    final response = await dio.get('/products', queryParameters: params);
    return ProductResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        errorNotification(e.response?.data['message']);
      } else {
        errorNotification(e.message ?? 'Error de conexión');
      }
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
    } on Exception
     catch (e) {
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
}