import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:teki_app/src/data/models/teki_model/customer.dart';
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
          await dio.get('/customers/$id');
      return Customer.fromJson(response.data);
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      if (e.response == null) {
        errorNotification('Sin conexión a internet');
        return Future.error('Sin conexión a internet');
      }
      final resData = e.response?.data;
      final errorMessage = (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ?? e.message ?? 'Error de conexión';
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
      
      if (e.response == null) {
      
        errorNotification('Sin conexión a internet');
      
        return Future.error('Sin conexión a internet');
      
      }
      
      final resData = e.response?.data;
      final responseMessage = (resData is Map ? (resData['mensaje'] ?? resData['message']) : null) ?? e.message ?? 'Error de conexión';
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
      if (e.response == null) {
        errorNotification('Sin conexión a internet');
        return Future.error('Sin conexión a internet');
      }
      errorNotification(e.toString());
      return [];
    } catch (e) {
      errorNotification(e.toString());
      return [];
    }
  }

  /// Paridad web (CustomerService.findByDocumento): filtra por tipo y número
  /// y se queda solo con la coincidencia exacta. Silencioso: se usa para
  /// autocompletar, un fallo equivale a "no encontrado".
  @override
  Future<Customer?> findByDocument(
    String tipoDocumento,
    String numeroDocumento,
  ) async {
    try {
      final response = await dio.get(
        '/customers',
        queryParameters: {
          'paginacion': false,
          'filtro': numeroDocumento,
          'limit': 20,
          'tipoDocumento': tipoDocumento,
        },
      );
      final data = response.data;
      final customers = data is List
          ? data.map((x) => Customer.fromJson(x)).toList()
          : CustomerResponse.fromJson(data).content;
      return customers
          .where(
            (c) =>
                c.tipoDocumento == tipoDocumento &&
                c.numeroDocumento == numeroDocumento,
          )
          .firstOrNull;
    } catch (e) {
      if (kDebugMode) debugPrint('findByDocument: $e');
      return null;
    }
  }

  /// `GET /customers/operations/by-phone`: el backend exige 9 dígitos y
  /// responde vacío cuando no hay cliente con ese celular.
  @override
  Future<Customer?> findByPhone(String telefono) async {
    if (!RegExp(r'^\d{9}$').hasMatch(telefono)) return null;
    try {
      final response = await dio.get(
        '/customers/operations/by-phone',
        queryParameters: {'telefono': telefono},
      );
      final data = response.data;
      return data is Map
          ? Customer.fromJson(Map<String, dynamic>.from(data))
          : null;
    } catch (e) {
      if (kDebugMode) debugPrint('findByPhone: $e');
      return null;
    }
  }
}
