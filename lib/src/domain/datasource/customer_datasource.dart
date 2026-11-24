import 'package:teki_app/src/data/models/teki_model/customer.dart';
import 'package:teki_app/src/data/models/response/customer.dart';

abstract class CustomersDatasource {
  /// Obtiene una lista paginada de clientes (usa CustomerResponse)
  Future<CustomerResponse> getCustomers(Map<String, dynamic> params);

  /// Obtiene un cliente por su ID único
  Future<Customer> getCustomerById(int id);

  /// Busca clientes por texto (nombre, documento, etc.), devuelve una lista directa
  /// Este método **no devuelve CustomerResponse**, solo una lista simple
  Future<List<Customer>> searchCustomers(String query);

  /// Crea un nuevo cliente
  Future<Customer> createCustomer(Customer customer);

  /// Actualiza un cliente existente
  Future<Customer> updateCustomer(Customer customer);
}
