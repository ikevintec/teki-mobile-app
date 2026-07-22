import 'package:teki_app/src/data/models/teki_model/customer.dart';
import 'package:teki_app/src/data/models/response/customer.dart';

abstract class CustomersRepository {
  /// Obtiene una lista paginada de clientes
  Future<CustomerResponse> getCustomers(Map<String, dynamic> params);

  /// Obtiene un cliente por su ID
  Future<Customer> getCustomerById(int id);

  /// Crea un nuevo cliente
  Future<Customer> createCustomer(Customer customer);

  /// Actualiza un cliente existente
  Future<Customer> updateCustomer(Customer customer);

  /// Busca clientes por texto (nombre, email, etc.), devuelve una lista directa
  Future<List<Customer>> searchCustomers(String query);
}
