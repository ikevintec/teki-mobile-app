import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/cutomer.dart';
import 'package:teki_app/src/data/repositories/customer_repository_imp.dart';
import 'package:teki_app/src/domain/repositories/customer_repository.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_state.dart';
import 'package:teki_app/src/utils/notifications.dart';

final customerSaleProvider =
    StateNotifierProvider<CustomerSaleNotifier, CustomerSaleState>((ref) {
  final CustomersRepository customersRepository = CustomersRepositoryImpl();
  return CustomerSaleNotifier(customersRepository: customersRepository, ref: ref);
});

class CustomerSaleNotifier extends StateNotifier<CustomerSaleState> {
  final CustomersRepository customersRepository;
  final Ref ref;

  CustomerSaleNotifier({required this.customersRepository, required this.ref})
      : super(CustomerSaleState(
          customer: Customer(),
          customers: [],
          selectedCustomer: null,
          isLoading: false,
          error: null,
          pageNumber: 0,
          perPage: 20,
          filterGlobal: '',
          totalElements: null,
          paginacion: false,
        ));

  Future<List<Customer>> getCustomerss(String filtro) async {
    state = state.copyWith(isLoading: true);
    try {
      final customers = await customersRepository.searchCustomers(filtro);
      state = state.copyWith(
        isLoading: false,
        customers: customers,
      );
      return customers;
    } catch (e) {
      errorNotification(e.toString());
      state = state.copyWith(isLoading: false);
      return [];
    }
  }

  void setFilterGlobal(String? value) {
    state = state.copyWith(filterGlobal: value ?? '');
  }

  void selectCustomer(Customer customer) {
    state = state.copyWith(selectedCustomer: customer);
  }

  void clearSelection(Customer customer) {
    state = state.copyWith(selectedCustomer: null);
  }

  void clearCustomers() {
    state = state.copyWith(customers: []);
  }

  void setCustomer({required int? id, required String nombre, required  String documento, required  String direccion,required  String email, required String telefono, required String tipoDocumento}){
    Customer customerToSet = Customer(
      id: id,
      razonSocial: nombre,
      numeroDocumento: documento,
      direccion: direccion,
      email: email,
      telefono: telefono,
      tipoDocumento: tipoDocumento 
    );
    state = state.copyWith(customer: customerToSet);
  }

  void setCustomerEntity(Customer customer) {
    state = state.copyWith(customer: customer);
  }

}
