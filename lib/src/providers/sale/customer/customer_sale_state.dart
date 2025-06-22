import 'package:teki_app/src/data/models/teki_model/cutomer.dart';

class CustomerSaleState {
  final List<Customer> customers;
  final Customer? selectedCustomer;
  final bool isLoading;
  final String? error;
  final int pageNumber;
  final int perPage;
  final String filterGlobal;
  final int? totalElements;
  final bool paginacion; // ✅ Se agregó esta línea

  CustomerSaleState({
    required this.customers,
    required this.selectedCustomer,
    required this.isLoading,
    required this.error,
    required this.pageNumber,
    required this.perPage,
    required this.filterGlobal,
    required this.totalElements,
    required this.paginacion, // ✅ Se agregó aquí también
  });

  CustomerSaleState copyWith({
    List<Customer>? customers,
    Customer? selectedCustomer,
    bool? isLoading,
    String? error,
    int? pageNumber,
    int? perPage,
    String? filterGlobal,
    int? totalElements,
    bool? paginacion, // ✅ y aquí
  }) {
    return CustomerSaleState(
      customers: customers ?? this.customers,
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      pageNumber: pageNumber ?? this.pageNumber,
      perPage: perPage ?? this.perPage,
      filterGlobal: filterGlobal ?? this.filterGlobal,
      totalElements: totalElements ?? this.totalElements,
      paginacion: paginacion ?? this.paginacion, // ✅
    );
  }
}
