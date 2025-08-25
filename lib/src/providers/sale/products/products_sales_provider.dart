import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/currency.dart';
import 'package:teki_app/src/data/models/teki_model/cutomer.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/ticketDetail.dart';
import 'package:teki_app/src/data/repositories/currency_repository_impl.dart';
import 'package:teki_app/src/data/repositories/products_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/currency_repository.dart';
import 'package:teki_app/src/domain/repositories/products_repository.dart';
import 'package:teki_app/src/providers/comprobantes/comprobante.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_provider.dart';
import 'package:teki_app/src/providers/sale/products/helpers/products_sale_notifier_setters.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/utils/notifications.dart';
import 'package:teki_app/src/utils/query_params_builders.dart';

final productSaleProvider =
    StateNotifierProvider<ProductsSaleNotifier, ProductsSaleState>(
  (ref) {
    final ProductsRepository productsRepository = ProductsRepositoryImpl();
    final CurrencyRepository currencyRepository = CurrencyRepositoryImpl();
    return ProductsSaleNotifier(
      productsRepository: productsRepository,
      currencyRepository: currencyRepository,
      ref: ref,
    );
  },
);

class ProductsSaleNotifier extends StateNotifier<ProductsSaleState>
    with ProductsSaleNotifierSettersMixin {
  @override
  final Ref ref;
  final ProductsRepository productsRepository;
  final CurrencyRepository currencyRepository;
  ProductsSaleNotifier({
    required this.ref,
    required this.productsRepository,
    required this.currencyRepository,
  }) : super(ProductsSaleState(
          tipoComprobante:
              ref.watch(sesionProvider).config!.tipoComprobantePorDefecto ??
                  'NV', // Factura
          productsSales: [],
          currencies: [],
          incIgv: true,
          currency: null,
          isLoading: true,
          error: null,
          pageNumber: 0,
          paginacion: true,
          perPage: 20,
          sortField: 'id',
          sortOrder: 1,
          filterGlobal: '',
          idPuntoVenta: null,
          otrosTributos: null,
          porcentajeDescuentoGlobal: null,
          flagRetencion: false,
          porcentajeRetencion:
              ref.watch(sesionProvider).config!.porcentajeRetencion ?? 0.0,
          codigoTipoOperacion: '0101',
        ));

  Future<List<Product>> getProducts(String? filter) async {
    setFilterGlobal(filter);
    try {
      final response =
          await productsRepository.getProducts(buildProductQueryParams(state));
      if (response.content != null || response.content!.isNotEmpty) {
        return response.content!;
      }
      return [];
    } catch (e) {
      errorNotification(e.toString());
      return [];
    }
  }

  void loadInitialData(int? id) async {
    setLoading(true);
    try {
      // Cargar currencies solo si no existen o si no se está editando
      if (state.currencies.isEmpty) {
        final response = await currencyRepository.getCurrencies();
        if (response.isNotEmpty) {
          state = state.copyWith(
            currencies: response,
            currency: response[0],
          );
        }
      }
      
      // Cargar datos de edición independientemente del estado de currencies
      if (id != null) {
        final comprobanteNotifier = ref.read(comprobanteProvider.notifier);
        // Cargar el comprobante y sus datos relacionados
        final customerNotifier = ref.read(customerSaleProvider.notifier);
        final productsSaleNotifier = ref.read(productSaleProvider.notifier);
        final ticketSaleNotifier = ref.read(ticketProvider.notifier);
        // Cargar el comprobante por ID
        Ticket comprobante = await comprobanteNotifier.fetchComprobanteById(id);
        ticketSaleNotifier.updateTicket(comprobante);
        customerNotifier.setCustomerEntity(comprobante.cliente?? Customer());
        productsSaleNotifier.setProductsSaleEntity(comprobante.items ?? [], monedaOrigen: comprobante.codigoMoneda);
        productsSaleNotifier.setIncIgv( comprobante.incIgv ?? true);
        productsSaleNotifier.setCurrency( comprobante.codigoMoneda ?? 'PEN');

        ticketSaleNotifier.setEdited(true);
      }
    } catch (e) {
      setError(e.toString());
      errorNotification(e.toString());
    } finally {
      setLoading(false);
    }
  }

  void removeProductSale(int index) {
    state = state.copyWith(
      productsSales: List.from(state.productsSales)..removeAt(index),
    );
    calculoTotal();
  }

}

class ProductsSaleState {
  final List<TicketDetail> productsSales;
  final List<Currency> currencies;
  final Currency? currency;
  final bool isLoading;
  final String? error;
  // Parámetros de configuración
  final bool incIgv;
  final String tipoComprobante;
  final double? porcentajeDescuentoGlobal;
  final double? otrosTributos;
  final bool flagRetencion;
  final double porcentajeRetencion;
  final String codigoTipoOperacion;
  // Parámetros de búsqueda
  final int? pageNumber;
  final bool? paginacion;
  final int? perPage;
  final String? sortField;
  final int? sortOrder;
  final String? filterGlobal;
  final int? idPuntoVenta;

  ProductsSaleState({
    required this.productsSales,
    required this.currencies,
    required this.currency,
    required this.isLoading,
    required this.error,
    required this.pageNumber,
    required this.paginacion,
    required this.perPage,
    required this.sortField,
    required this.sortOrder,
    required this.filterGlobal,
    required this.idPuntoVenta,
    required this.incIgv,
    required this.tipoComprobante,
    required this.otrosTributos,
    required this.porcentajeDescuentoGlobal,
    required this.flagRetencion,
    required this.porcentajeRetencion,
    required this.codigoTipoOperacion,
  });

  ProductsSaleState copyWith({
    List<TicketDetail>? productsSales,
    List<Currency>? currencies,
    Currency? currency,
    bool? isLoading,
    String? error,
    //configuración
    bool? incIgv,
    String? tipoComprobante,
    double? otrosTributos,
    double? porcentajeDescuentoGlobal,
    bool? flagRetencion,
    double? porcentajeRetencion,
    String? codigoTipoOperacion,
    // búsqueda
    int? pageNumber,
    bool? paginacion,
    int? perPage,
    String? sortField,
    int? sortOrder,
    String? filterGlobal,
    int? idPuntoVenta,
  }) {
    return ProductsSaleState(
      productsSales: productsSales ?? this.productsSales,
      currencies: currencies ?? this.currencies,
      currency: currency ?? this.currency,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      pageNumber: pageNumber ?? this.pageNumber,
      paginacion: paginacion ?? this.paginacion,
      perPage: perPage ?? this.perPage,
      sortField: sortField ?? this.sortField,
      sortOrder: sortOrder ?? this.sortOrder,
      filterGlobal: filterGlobal ?? this.filterGlobal,
      idPuntoVenta: idPuntoVenta ?? this.idPuntoVenta,
      incIgv: incIgv ?? this.incIgv,
      tipoComprobante: tipoComprobante ?? this.tipoComprobante,
      otrosTributos: otrosTributos ?? this.otrosTributos,
      porcentajeDescuentoGlobal:
      porcentajeDescuentoGlobal ?? this.porcentajeDescuentoGlobal,
      flagRetencion: flagRetencion ?? this.flagRetencion,
      porcentajeRetencion: porcentajeRetencion ?? this.porcentajeRetencion,
      codigoTipoOperacion: codigoTipoOperacion ?? this.codigoTipoOperacion,
    );
  }
}
