import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/response/purchase_response.dart';
import 'package:teki_app/src/data/models/teki_model/purchase.dart';
import 'package:teki_app/src/data/models/teki_model/supplier.dart';
import 'package:teki_app/src/domain/datasource/purchases_datasource.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';

class RemotePurchases extends PurchasesDatasource {
  final Dio dio = ApiClient.dio;

  String _message(DioException e, String fallback) {
    final resData = e.response?.data;
    return (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ??
        e.message ??
        fallback;
  }

  @override
  Future<PurchaseResponse> getPurchases(Map<String, dynamic> params) async {
    try {
      final response = await dio.get('/purchases', queryParameters: params);
      return PurchaseResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      if (e.response == null) rethrow;
      return Future.error('Compras: ${_message(e, 'Error de conexión')}');
    } catch (e) {
      return Future.error('Compras: ${e.toString()}');
    }
  }

  @override
  Future<Purchase> savePurchase(Purchase purchase) async {
    try {
      final response = await dio.post('/purchases', data: purchase.toJson());
      return Purchase.fromJson(response.data);
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      if (e.response == null) rethrow;
      return Future.error(_message(e, 'Error al registrar la compra'));
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  @override
  Future<void> cancelPurchase(int id, String motivo) async {
    try {
      await dio.delete('/purchases/$id',
          queryParameters: {'motivoAnulacion': motivo});
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      if (e.response == null) rethrow;
      return Future.error(_message(e, 'Error al anular la compra'));
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  @override
  Future<List<Supplier>> searchSuppliers(String query) async {
    try {
      final response = await dio.get('/suppliers', queryParameters: {
        'paginacion': 'false',
        if (query.isNotEmpty) 'filtro': query,
      });
      final data = response.data is List
          ? response.data as List
          : (response.data['content'] ?? []);
      return List<Supplier>.from(data.map((e) => Supplier.fromJson(e)));
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      if (e.response == null) rethrow;
      return Future.error('Proveedores: ${_message(e, 'Error de conexión')}');
    } catch (e) {
      return Future.error('Proveedores: ${e.toString()}');
    }
  }
}
