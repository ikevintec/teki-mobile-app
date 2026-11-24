import 'package:teki_app/src/data/services/distribuidor/comercial_service.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/customer.dart';
import 'package:teki_app/src/data/repositories/customer_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/customer_repository.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_state.dart';
import 'package:teki_app/src/utils/notifications.dart';

final customerSaleProvider=StateNotifierProvider<CustomerSaleNotifier,CustomerSaleState>(crearClienteVenta);
CustomerSaleNotifier crearClienteVenta(Ref ref) {
  ref.watch(sesionProvider.select((s)=>s.claveContexto));
  return CustomerSaleNotifier(ref:ref,customersRepository:CustomersRepositoryImpl());
}

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

  int _revisionPrecioCliente=0;
  Future<bool> aplicarPrecioCliente(int? id) async {
    final s=ref.read(sesionProvider);
    if(s.comercial?.activo!=true)return true;
    final revision=++_revisionPrecioCliente;
    try{
      final c=await ComercialService().cargar(s.office!.id!,cliente:id,
          config:s.config?.configuracionDistribuidor);
      if(!mounted || revision!=_revisionPrecioCliente || state.customer.id!=id ||
          ref.read(sesionProvider).office?.id!=s.office?.id || ref.read(sesionProvider).login.user?.id!=s.login.user?.id)return false;
      ref.read(ticketProvider.notifier).updateTicket(ref.read(ticketProvider).ticket.copyWith(tipoPrecioCabeceraId:c.cabecera));
      return true;
    }catch(_){errorNotification('No se pudo cargar el tipo de precio del cliente. Reintenta antes de continuar.');return false;}
  }

  void setCustomerEntity(Customer customer) {
    state = state.copyWith(customer: customer);
  }

}
