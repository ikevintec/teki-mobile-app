import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail_group_option.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail_preparation_option.dart';
import 'package:teki_app/src/data/models/teki_model/config.dart';
import 'package:teki_app/src/data/models/teki_model/customer.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/online_order.dart';
import 'package:teki_app/src/data/models/teki_model/order_restaurant.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/repositories/customer_repository_impl.dart';
import 'package:teki_app/src/data/repositories/online_order_repository_impl.dart';
import 'package:teki_app/src/data/repositories/products_repository_impl.dart';
import 'package:teki_app/src/data/repositories/restaurant_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/customer_repository.dart';
import 'package:teki_app/src/domain/repositories/online_order_repository.dart';
import 'package:teki_app/src/domain/repositories/products_repository.dart';
import 'package:teki_app/src/domain/repositories/restaurant_repository.dart';
import 'package:teki_app/src/utils/price.dart';

class OnlineOrderCommandDraft {
  final OnlineOrder onlineOrder;
  final Customer customer;
  final List<CommandDetail> details;

  const OnlineOrderCommandDraft({
    required this.onlineOrder,
    required this.customer,
    required this.details,
  });
}

/// Traduce un pedido online de menú al mismo modelo que usa Restaurante.
/// Se mantiene aislado para que editar y facturar compartan exactamente el
/// mismo mapeo sin alterar los demás flujos de comandas.
class OnlineOrderWorkflowService {
  final OnlineOrderRepository onlineOrderRepository;
  final ProductsRepository productsRepository;
  final CustomersRepository customersRepository;
  final RestaurantRepository restaurantRepository;

  OnlineOrderWorkflowService({
    OnlineOrderRepository? onlineOrderRepository,
    ProductsRepository? productsRepository,
    CustomersRepository? customersRepository,
    RestaurantRepository? restaurantRepository,
  }) : onlineOrderRepository =
           onlineOrderRepository ?? OnlineOrderRepositoryImpl(),
       productsRepository = productsRepository ?? ProductsRepositoryImpl(),
       customersRepository = customersRepository ?? CustomersRepositoryImpl(),
       restaurantRepository =
           restaurantRepository ?? RestaurantRepositoryImpl();

  Future<OnlineOrderCommandDraft> prepare(
    int onlineOrderId,
    Office office,
    ConfigCompany? config,
  ) async {
    final order = await onlineOrderRepository.getOrder(onlineOrderId);
    _validate(order);

    final items = order.items.where((item) => item.idProducto != null).toList();
    final details = await Future.wait(
      items.map((item) async {
        final product = await productsRepository.getProductById(
          item.idProducto!,
        );
        return _buildDetail(item, product, office, config);
      }),
    );
    final fallbackCustomer = _buildCustomer(order);
    final customer =
        await findSavedCustomer(fallbackCustomer) ?? fallbackCustomer;
    return OnlineOrderCommandDraft(
      onlineOrder: order,
      customer: customer,
      details: details,
    );
  }

  Future<OrderRestaurant> createDirectOrder(
    int onlineOrderId,
    Office office,
    ConfigCompany? config,
  ) async {
    final draft = await prepare(onlineOrderId, office, config);
    return createFromDraft(draft, office, draft.details);
  }

  Future<OrderRestaurant> createFromDraft(
    OnlineOrderCommandDraft draft,
    Office office,
    List<CommandDetail> details,
  ) {
    final source = draft.onlineOrder;
    final customer = draft.customer;
    final order = OrderRestaurant(
      comandas: [Command(items: details)],
      puntoVenta: office,
      tipo: source.tipoEntrega == 'DELIVERY'
          ? 'PEDIDO_FORANEO'
          : 'PEDIDO_LOCAL',
      cliente: customer,
      nombreCliente: customer.razonSocial,
      tipoDocumentoReceptor: customer.tipoDocumento,
      numeroDocumentoReceptor: customer.numeroDocumento,
      denominacionReceptor: customer.razonSocial,
      direccionReceptor: customer.direccionCompleta,
      emailReceptor: customer.email,
      telefonoReceptor: customer.telefono,
      montoDelivery: source.montoDelivery,
      tipoDireccion: 'CASA',
      direccionCompleta: source.direccionEntrega,
      direccion: source.direccionEntrega,
      referencia: source.referenciaEntrega,
      codigoDepartamento: source.codigoDepartamento,
      codigoProvincia: source.codigoProvincia,
      codigoDistrito: source.codigoDistrito,
      latitud: source.latitud,
      longitud: source.longitud,
      idPedidoTiendaOnline: source.id,
    );
    return restaurantRepository.createOrder(order);
  }

  void _validate(OnlineOrder order) {
    if (order.tipo != 'MENU') {
      throw StateError('Solo los pedidos de menú pueden generar una comanda.');
    }
    if (order.estado != 'ACEPTADO') {
      throw StateError('Debe aceptar el pedido antes de generar la comanda.');
    }
    if (!order.items.any((item) => item.idProducto != null)) {
      throw StateError('El pedido no tiene productos para generar la comanda.');
    }
  }

  Customer _buildCustomer(OnlineOrder order) {
    // Paridad web: boleta simple va con tipoDocumento '1' y sin número (no
    // se usa 00000000 ni otro DNI genérico).
    final isSimpleReceipt = order.tipoComprobante == 'BOLETA_SIMPLE';
    final documentType = order.tipoComprobante == 'FACTURA'
        ? '6'
        : (order.tipoComprobante == 'BOLETA_DNI' || isSimpleReceipt)
        ? '1'
        : (order.tipoDocumentoCliente ?? '1');
    final documentNumber = isSimpleReceipt
        ? null
        : order.numeroDocumentoCliente?.trim().isNotEmpty == true
        ? order.numeroDocumentoCliente!.trim()
        : null;
    return Customer(
      tipoDocumento: documentType,
      numeroDocumento: documentNumber,
      razonSocial: order.nombreCliente,
      email: order.emailCliente,
      telefono: order.telefonoCliente,
      tipoDireccion: 'CASA',
      direccionCompleta: order.direccionEntrega,
      direccion: order.direccionEntrega,
      referencia: order.referenciaEntrega,
      codigoDepartamento: order.codigoDepartamento,
      codigoProvincia: order.codigoProvincia,
      codigoDistrito: order.codigoDistrito,
      latitud: order.latitud,
      longitud: order.longitud,
    );
  }

  /// Paridad web (findCustomerPedidoOnline): con documento busca solo por
  /// tipo + número exacto; sin documento, por celular
  /// (`/customers/operations/by-phone`). Devuelve el cliente guardado para
  /// reemplazar los datos del pedido, o null si no hay coincidencia.
  Future<Customer?> findSavedCustomer(Customer target) async {
    final documentType = target.tipoDocumento?.trim() ?? '';
    final document = target.numeroDocumento?.trim() ?? '';
    if (documentType.isNotEmpty && document.isNotEmpty) {
      return customersRepository.findByDocument(documentType, document);
    }
    final phone = target.telefono?.trim() ?? '';
    if (phone.isEmpty) return null;
    return customersRepository.findByPhone(phone);
  }

  CommandDetail _buildDetail(
    OnlineOrderItem item,
    Product product,
    Office office,
    ConfigCompany? config,
  ) {
    final groups = item.opciones
        .where((option) => option.tipo == 'GRUPO')
        .map((option) => _buildGroupOption(option, product))
        .toList();
    final additionalCost = groups.fold<double>(
      0,
      (sum, option) => sum + (option.precio ?? 0) * (option.cantidad ?? 0),
    );
    final unitPrice = item.precioUnitario != 0
        ? item.precioUnitario
        : getPriceProduct(product, office, {'igv': config?.igv});
    return CommandDetail(
      producto: product,
      cantidad: item.cantidad == 0 ? 1 : item.cantidad,
      precioVenta: (unitPrice - additionalCost).clamp(0, double.infinity),
      nota: item.nota,
      paraLlevar: false,
      grupoProductoOpciones: groups,
      preparacionProductoOpciones: item.opciones
          .where((option) => option.tipo == 'PREPARACION')
          .map((option) => _buildPreparationOption(option, product))
          .toList(),
    );
  }

  CommandDetailGroupOption _buildGroupOption(
    OnlineOrderItemOption option,
    Product product,
  ) {
    final group = product.grupos
        ?.where((item) => item.id == option.idGrupo)
        .firstOrNull;
    final groupOption = group?.opciones
        ?.where((item) => item.id == option.idOpcion)
        .firstOrNull;
    final optionProduct =
        groupOption?.producto ??
        (option.idProductoOpcion == null
            ? null
            : Product(
                id: option.idProductoOpcion,
                nombre: option.nombreProductoOpcion,
              ));
    return CommandDetailGroupOption(
      producto: optionProduct,
      cantidad: option.cantidad == 0 ? 1 : option.cantidad,
      idGrupo: option.idGrupo,
      idOpcion: option.idOpcion,
      nombreGrupo: option.nombreGrupo ?? group?.nombre,
      nombreOpcion: option.nombreOpcion ?? groupOption?.nombre,
      precio:
          option.precio ?? option.precioUnitario ?? groupOption?.precio ?? 0,
      porcion: option.porcion ?? groupOption?.porcion ?? 0,
    );
  }

  CommandDetailPreparationOption _buildPreparationOption(
    OnlineOrderItemOption option,
    Product product,
  ) {
    final preparation = product.preparaciones
        ?.where((item) => item.preparacion?.id == option.idGrupo)
        .firstOrNull;
    final selected = preparation?.preparacion?.opciones
        ?.where((item) => item.id == option.idOpcion)
        .firstOrNull;
    return CommandDetailPreparationOption(
      idPreparacion: option.idGrupo,
      idOpcion: option.idOpcion,
      nombrePreparacion: option.nombreGrupo ?? preparation?.preparacion?.nombre,
      nombreOpcion: option.nombreOpcion ?? selected?.opcion,
    );
  }
}
