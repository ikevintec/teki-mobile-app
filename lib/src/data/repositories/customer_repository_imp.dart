import 'package:teki_app/src/data/datasource/remote_customer.dart';
import 'package:teki_app/src/data/models/teki_model/cutomer.dart';
import 'package:teki_app/src/data/models/response/customer.dart';
import 'package:teki_app/src/domain/datasource/customer_datasource.dart';
import 'package:teki_app/src/domain/repositories/customer_repository.dart';

class CustomersRepositoryImpl extends CustomersRepository {
  final CustomersDatasource customersDatasource;

  CustomersRepositoryImpl({CustomersDatasource? customersDatasource})
      : customersDatasource = customersDatasource ?? RemoteCustomers();

  @override
  Future<CustomerResponse> getCustomers(Map<String, dynamic> params) async {
    return await customersDatasource.getCustomers(params);
  }

  @override
  Future<Customer> getCustomerById(int id) async {
    return await customersDatasource.getCustomerById(id);
  }

  @override
  Future<Customer> createCustomer(Customer customer) async {
    return await customersDatasource.createCustomer(customer);
  }

  @override
  Future<Customer> updateCustomer(Customer customer) async {
    return await customersDatasource.updateCustomer(customer);
  }

  @override
  Future<List<Customer>> searchCustomers(String query) async {
    return await customersDatasource.searchCustomers(query);
  }
}
