import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/cutomer.dart';
import 'package:teki_app/src/data/repositories/customer_repository_imp.dart';
import 'package:teki_app/src/domain/repositories/customer_repository.dart';
import 'package:teki_app/src/utils/notifications.dart';
import 'package:teki_app/src/utils/query_params_builders.dart';

final customersProvider = StateNotifierProvider<CustomersStateNotifier, CustomersState>((ref) {
  final repositorio = CustomersRepositoryImpl();
  return CustomersStateNotifier(customersRepository: repositorio, ref: ref);
});

class CustomersStateNotifier extends StateNotifier<CustomersState> {
  final CustomersRepository customersRepository;
  final Ref ref;

  CustomersStateNotifier({required this.customersRepository, required this.ref})
      : super(CustomersState.initial());

  Future<void> loadFirstPage() async {
    state = CustomersState.initial();
    state = state.copyWith(isLoading: true);
    try {
      final customers = await customersRepository.getCustomers(buildCustomersQueryParams(state));
      setCustomers(customers.content);
    } catch (e) {
      errorNotification(e.toString());
    } finally {
      setLoading(false);
    }

  }

  Future<void> loadMorePages() async {
    if (state.isLoading == true) return;
    if (state.totalElements != null && state.customers!.length >= state.totalElements!) {
      state = state.copyWith(paginacion: false);
      return;
    }

    state = state.copyWith(isLoading: true, pageNumber: state.pageNumber + 1);
    try {
      final customers = await customersRepository.getCustomers(buildCustomersQueryParams(state));
      final allCustomers = [...?state.customers, ...customers.content];
      setCustomers(allCustomers);
    } catch (e) {
      errorNotification(e.toString());
    } finally {
      setLoading(false);
    }
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setCustomers(List<Customer> customers) {
    state = state.copyWith(customers: customers);
  }

  void setFiltro(String? value) {
    state = state.copyWith(filtro: value ?? '');
  }

  void setTelefono(String? value) {
    state = state.copyWith(telefono: value ?? '');
  }

  void setEmail(String? value) {
    state = state.copyWith(email: value ?? '');
  }

  void clearCustomers() {
    state = state.copyWith(customers: []);
  }

  void clearState() {
    state = CustomersState.initial();
  }

}


class CustomersState{
  final List<Customer>? customers;
  final bool? isLoading;
  final int pageNumber;
  final int perPage;
  final String filtro;
  final int? totalElements;
  final bool paginacion;
  final String telefono;
  final String email;

  CustomersState({
    required this.customers,
    required this.isLoading,
    required this.pageNumber,
    required this.perPage,
    required this.filtro,
    required this.totalElements,
    required this.paginacion,
    required this.telefono,
    required this.email,
  });

  CustomersState copyWith({
    List<Customer>? customers,
    bool? isLoading,
    int? pageNumber,
    int? perPage,
    String? filtro,
    int? totalElements,
    bool? paginacion,
    String? telefono,
    String? email,
  }) {
    return CustomersState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      pageNumber: pageNumber ?? this.pageNumber,
      perPage: perPage ?? this.perPage,
      filtro: filtro ?? this.filtro,
      totalElements: totalElements ?? this.totalElements,
      paginacion: paginacion ?? this.paginacion,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
    );
  }

  factory CustomersState.initial() {
    return CustomersState(
      customers: [],
      isLoading: false,
      pageNumber: 0,
      perPage: 10,
      totalElements: null,
      paginacion: false,
      filtro: '',
      telefono: '',
      email: '',
    );
  }

}