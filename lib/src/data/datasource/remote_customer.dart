import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/teki_model/cutomer.dart';
import 'package:teki_app/src/data/models/response/customer.dart';
import 'package:teki_app/src/domain/datasource/customer_datasource.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import 'package:teki_app/src/utils/notifications.dart';

class RemoteCustomers extends CustomersDatasource {
  final Dio dio = ApiClient.dio;

  @override
  Future<Customer> getCustomerById(int id) async {
    try {
      final response =
          await dio.get('/customers/$id'); // ✅ Corregido: era /products/$id
      return Customer.fromJson(response.data);
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      final errorMessage =
          e.response?.data['message'] ?? e.message ?? 'Error de conexión';
      return Future.error(errorMessage);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  @override
  @override
  Future<CustomerResponse> getCustomers(Map<String, dynamic> params) async {
    try {
      final response = await dio.get('/customers', queryParameters: params);
      final data = response.data;

      if (data is List) {
        final customers = data.map((e) => Customer.fromJson(e)).toList();

        return CustomerResponse(
          content: customers,
          empty: customers.isEmpty,
          first: true,
          last: true,
          number: 0,
          pageable: null,
          size: customers.length,
          sort: null,
          totalElements: customers.length,
          totalPages: 1,
        );
      }

      return CustomerResponse.fromJson(data);
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      
      String responseMessage = 'Error de conexión';
      if (e.response != null) {
        responseMessage = e.response?.data['message'] ?? 'Error de conexión';
      } else {
        responseMessage = e.message ?? 'Error de conexión';
      }
      return Future.error(responseMessage);
    } catch (e) {
      errorNotification(e.toString());
      return CustomerResponse(
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
  Future<Customer> createCustomer(Customer customer) async {
    try {
      final response = await dio.post('/customers', data: customer.toJson());
      return Customer.fromJson(response.data);
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      return Future.error(e.toString());
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  @override
  Future<Customer> updateCustomer(Customer customer) async {
    try {
      final response = await dio.put('/customers', data: customer.toJson());
      return Customer.fromJson(response.data);
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      return Future.error(e.toString());
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  @override
  Future<List<Customer>> searchCustomers(String query) async {
    try {
      final response = await dio.get('/customers', queryParameters: {
        'paginacion': false,
        'filtro': query,
        'limit': 20,
        'tipoDocumento': ['6', '1', '4', '0', '7', 'A']
      });

      final data = response.data;

      // Si devuelve una lista directamente
      if (data is List) {
        return data.map((x) => Customer.fromJson(x)).toList();
      }

      // Si devuelve un objeto con 'content'
      final customerResponse = CustomerResponse.fromJson(data);
      return customerResponse.content;
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      errorNotification(e.toString());
      return [];
    } catch (e) {
      errorNotification(e.toString());
      return [];
    }
  }
}
