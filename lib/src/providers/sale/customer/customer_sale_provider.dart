import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/cutomer.dart';
import 'package:teki_app/src/data/repositories/customer_repository_imp.dart';
import 'package:teki_app/src/domain/repositories/customer_repository.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_state.dart';
import 'package:teki_app/src/utils/notifications.dart';
import 'package:teki_app/src/utils/query_params_builders.dart';

final customerSaleProvider =
    StateNotifierProvider<CustomerSaleNotifier, CustomerSaleState>((ref) {
  final CustomersRepository customersRepository = CustomersRepositoryImpl();
  return CustomerSaleNotifier(customersRepository: customersRepository);
});

class CustomerSaleNotifier extends StateNotifier<CustomerSaleState> {
  final CustomersRepository customersRepository;

  CustomerSaleNotifier({required this.customersRepository})
      : super(CustomerSaleState(
          customers: [],
          selectedCustomer: null,
          isLoading: false,
          error: null,
          pageNumber: 0,
          perPage: 20,
          filterGlobal: '',
          totalElements: null,
          paginacion: false, // ✅ nuevo campo
        ));

  // Future<List<Customer>> getProducts(String? filter) async {
  //   setFilterGlobal(filter);
  //   try {
  //     final response = await customersRepository
  //         .getCustomers(buildProductQueryParams(state));
  //     if (response.content != null || response.content!.isNotEmpty) {
  //       return response.content!;
  //     }
  //     return [];
  //   } catch (e) {
  //     errorNotification(e.toString());
  //     return [];
  //   }
  // }

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

  // Future<List<Customer>> fetchCustomers([String? filter]) async {
  //   state = state.copyWith(isLoading: true, filterGlobal: filter ?? '');
  //   try {
  //     final response = await customersRepository.getCustomers({
  //       'paginacion': state.paginacion,
  //       'filtro': state.filterGlobal,
  //       'limit': state.perPage,
  //     });

  //     state = state.copyWith(
  //       customers: response.content ?? [],
  //       totalElements: response.totalElements,
  //       isLoading: false,
  //       error: null,
  //     );

  //     return response.content ??
  //         []; // <-- IMPORTANTE: necesitas retornar algo si el método es Future<List<Customer>>
  //   } catch (e) {
  //     state = state.copyWith(
  //       isLoading: false,
  //       error: e.toString(),
  //     );
  //     errorNotification(e.toString());
  //     return []; // <-- También deberías retornar una lista vacía en caso de error
  //   }
  // }

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
}
