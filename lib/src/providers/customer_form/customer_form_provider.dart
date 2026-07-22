import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/customer.dart';
import 'package:teki_app/src/data/repositories/customer_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/customer_repository.dart';
import 'package:teki_app/src/providers/customers/customers.dart';
import 'package:teki_app/src/utils/notifications.dart';

final customerFormProvider = StateNotifierProvider<CustomerFormNotifier, CustomerFormState>((ref) {
  final repository = CustomersRepositoryImpl();
  return CustomerFormNotifier(customersRepository: repository, ref: ref);
});

class CustomerFormNotifier extends StateNotifier<CustomerFormState> {
  final CustomersRepository customersRepository;
  final Ref ref;

  CustomerFormNotifier({required this.customersRepository, required this.ref})
      : super(CustomerFormState.initial());

  Future<void> loadCustomerById(int id) async {
    try {
      final customer = await customersRepository.getCustomerById(id);
      state = state.copyWith(
        customer: customer,
        isEditing: true,
        isLoading: false,
      );
    } catch (e) {
      errorNotification('Error al cargar cliente: ${e.toString()}');
      state = state.copyWith(isLoading: false, isEditing: true);
    }
  }

  void setCustomerData({
    String? razonSocial,
    String? numeroDocumento,
    String? tipoDocumento,
    String? direccion,
    String? email,
    String? telefono,
  }) {
    final currentCustomer = state.customer ?? Customer();
    
    final updatedCustomer = Customer(
      id: currentCustomer.id,
      idIntegration: currentCustomer.idIntegration,
      razonSocial: razonSocial ?? currentCustomer.razonSocial,
      numeroDocumento: numeroDocumento ?? currentCustomer.numeroDocumento,
      tipoDocumento: tipoDocumento ?? currentCustomer.tipoDocumento,
      direccion: direccion ?? currentCustomer.direccion,
      direccionCompleta: direccion ?? currentCustomer.direccionCompleta,
      email: email ?? currentCustomer.email,
      telefono: telefono ?? currentCustomer.telefono,
      genero: currentCustomer.genero,
      giro: currentCustomer.giro,
      fechaNacimiento: currentCustomer.fechaNacimiento,
      referido: currentCustomer.referido,
      expediente: currentCustomer.expediente,
      tipoDireccion: currentCustomer.tipoDireccion,
      numero: currentCustomer.numero,
      numeroDepartamento: currentCustomer.numeroDepartamento,
      referencia: currentCustomer.referencia,
      codigoDepartamento: currentCustomer.codigoDepartamento,
      codigoProvincia: currentCustomer.codigoProvincia,
      codigoDistrito: currentCustomer.codigoDistrito,
      latitud: currentCustomer.latitud,
      longitud: currentCustomer.longitud,
      codigoCiudad: currentCustomer.codigoCiudad,
      empresa: currentCustomer.empresa,
      estado: currentCustomer.estado,
      porDefecto: currentCustomer.porDefecto,
    );
    
    state = state.copyWith(customer: updatedCustomer);
  }

  Customer prepareCustomerForCreate() {
    final customer = state.customer ?? Customer();
    return Customer(
      razonSocial: customer.razonSocial?.trim(),
      numeroDocumento: customer.numeroDocumento?.trim(),
      tipoDocumento: customer.tipoDocumento?.trim(),
      direccion: customer.direccion?.trim(),
      direccionCompleta: customer.direccionCompleta?.trim() ?? customer.direccion?.trim(),
      email: customer.email?.trim(),
      telefono: customer.telefono?.trim(),
      estado: true,
    );
  }

  Customer prepareCustomerForUpdate() {
    final customer = state.customer ?? Customer();
    return Customer(
      id: customer.id,
      idIntegration: customer.idIntegration,
      razonSocial: customer.razonSocial?.trim(),
      numeroDocumento: customer.numeroDocumento?.trim(),
      tipoDocumento: customer.tipoDocumento?.trim(),
      direccion: customer.direccion?.trim(),
      direccionCompleta: customer.direccionCompleta?.trim() ?? customer.direccion?.trim(),
      email: customer.email?.trim(),
      telefono: customer.telefono?.trim(),
      genero: customer.genero,
      giro: customer.giro,
      fechaNacimiento: customer.fechaNacimiento,
      referido: customer.referido,
      expediente: customer.expediente,
      tipoDireccion: customer.tipoDireccion,
      numero: customer.numero,
      numeroDepartamento: customer.numeroDepartamento,
      referencia: customer.referencia,
      codigoDepartamento: customer.codigoDepartamento,
      codigoProvincia: customer.codigoProvincia,
      codigoDistrito: customer.codigoDistrito,
      latitud: customer.latitud,
      longitud: customer.longitud,
      codigoCiudad: customer.codigoCiudad,
      empresa: customer.empresa,
      estado: customer.estado,
      porDefecto: customer.porDefecto,
    );
  }

  Future<void> proccessCustomerForm() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (state.isEditing) {
        final customerToUpdate = prepareCustomerForUpdate();
        await customersRepository.updateCustomer(customerToUpdate);
        successNotification('Cliente actualizado con éxito');
      } else {
        final customerToCreate = prepareCustomerForCreate();
        await customersRepository.createCustomer(customerToCreate);
        successNotification('Cliente creado con éxito');
      }
      state = state.copyWith(isLoading: false);
      ref.read(customersProvider.notifier).clearState();
      await ref.read(customersProvider.notifier).loadFirstPage();
    } catch (e) {
      errorNotification('Error al procesar el formulario: ${e.toString()}');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void resetForm() {
    state = CustomerFormState.initial();
  }

  Future<void> setFormMode({int? customerId}) async{
    // Resetear estado completamente antes de cargar
    state = CustomerFormState.initial();
    
    if (customerId != null) {
      state = state.copyWith(isEditing: true, isLoading: true);
      await loadCustomerById(customerId);
    } else {
      state = state.copyWith(isEditing: false, isLoading: false, customer: Customer());
    }
    state = state.copyWith(
      error: null,
    );
  }
}

class CustomerFormState {
  final Customer? customer;
  final bool isLoading;
  final bool isEditing;
  final String? error;

  CustomerFormState({
    this.customer,
    required this.isLoading,
    required this.isEditing,
    this.error,
  });

  CustomerFormState copyWith({
    Customer? customer,
    bool? isLoading,
    bool? isEditing,
    String? error,
  }) {
    return CustomerFormState(
      customer: customer ?? this.customer,
      isLoading: isLoading ?? this.isLoading,
      isEditing: isEditing ?? this.isEditing,
      error: error ?? this.error,
    );
  }

  factory CustomerFormState.initial() {
    return CustomerFormState(
      customer: null,
      isLoading: false,
      isEditing: false,
      error: null,
    );
  }
}