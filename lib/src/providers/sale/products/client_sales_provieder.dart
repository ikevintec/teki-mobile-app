import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/cutomer.dart';
import 'package:teki_app/src/data/repositories/customer_repository_imp.dart';
import 'package:teki_app/src/domain/repositories/customer_repository.dart';
import 'package:teki_app/src/utils/notifications.dart';
import 'package:teki_app/src/utils/query_params_builders.dart';

final customerSaleProvider =
    StateNotifierProvider<CustomerSaleNotifier, CustomerSaleState>(
  (ref) {
    final CustomersRepository customersRepository = CustomersRepositoryImpl();
    return CustomerSaleNotifier(
      customersRepository: customersRepository,
    );
  },
);

class CustomerSaleNotifier extends StateNotifier<CustomerSaleState> {
  final CustomersRepository customersRepository;

  CustomerSaleNotifier({
    required this.customersRepository,
  }) : super(CustomerSaleState(
          customers: [],
          selectedCustomer: null,
          isLoading: false,
          error: null,
          pageNumber: 0,
          paginacion: true,
          perPage: 20,
          sortField: 'id',
          sortOrder: 1,
          filterGlobal: '',
        ));

  Future<List<Customer>> getCustomers(String? filter) async {
    state = state.copyWith(filterGlobal: filter, isLoading: true);
    try {
      final params = {
        'page': state.pageNumber,
        'size': state.perPage,
        'sort': '${state.sortField},${state.sortOrder == 1 ? 'asc' : 'desc'}',
        if (filter != null && filter.isNotEmpty) 'search': filter,
      };

      final response = await customersRepository.getCustomers(params);

      final customers = response.content ?? [];

      state = state.copyWith(
        customers: customers,
        isLoading: false,
        error: null,
      );

      return customers;
    } catch (e) {
      final errorMsg = e.toString();
      state = state.copyWith(isLoading: false, error: errorMsg);
      errorNotification(errorMsg);
      return [];
    }
  }

  void selectCustomer(Customer customer) {
    state = state.copyWith(selectedCustomer: customer);
  }

  void clearSelectedCustomer() {
    state = state.copyWith(selectedCustomer: null);
  }
}

class CustomerSaleState {
  final List<Customer> customers;
  final Customer? selectedCustomer;
  final bool isLoading;
  final String? error;

  // Parámetros de búsqueda y paginación
  final int pageNumber;
  final bool paginacion;
  final int perPage;
  final String sortField;
  final int sortOrder;
  final String? filterGlobal;

  CustomerSaleState({
    required this.customers,
    required this.selectedCustomer,
    required this.isLoading,
    required this.error,
    required this.pageNumber,
    required this.paginacion,
    required this.perPage,
    required this.sortField,
    required this.sortOrder,
    required this.filterGlobal,
  });

  CustomerSaleState copyWith({
    List<Customer>? customers,
    Customer? selectedCustomer,
    bool? isLoading,
    String? error,
    int? pageNumber,
    bool? paginacion,
    int? perPage,
    String? sortField,
    int? sortOrder,
    String? filterGlobal,
  }) {
    return CustomerSaleState(
      customers: customers ?? this.customers,
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      pageNumber: pageNumber ?? this.pageNumber,
      paginacion: paginacion ?? this.paginacion,
      perPage: perPage ?? this.perPage,
      sortField: sortField ?? this.sortField,
      sortOrder: sortOrder ?? this.sortOrder,
      filterGlobal: filterGlobal ?? this.filterGlobal,
    );
  }
}
