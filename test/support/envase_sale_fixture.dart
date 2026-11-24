import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/response/login.dart';
import 'package:teki_app/src/data/models/teki_model/config.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/product_price.dart';
import 'package:teki_app/src/data/models/teki_model/currency.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/ticket_detail.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/sale/products/helpers/products_sale_notifier_setters.dart';

final testSesion = SesionState(
  login: LoginResponse(),
  office: Office(id: 1),
  config: ConfigCompany(
    igv: 0.18,
    porcentajeRecargoPorItem: 0,
    porcentajeRetencion: 0,
    permitirRetornoEnvase: true,
    inventario: true,
  ),
);
final product = Product(
  id: 1,
  moneda: 'PEN',
  igv: true,
  preciosPorPuntoVenta: false,
  envaseRetornable: true,
  productoEnvase: Product(id: 2),
  preciosVenta: [
    ProductPrice(tipoPrecio: 'POR_DEFECTO', precio: 28),
    ProductPrice(tipoPrecio: 'ESPECIAL', precio: 12, paraCanje: true),
    ProductPrice(
      tipoPrecio: 'MAYOREO',
      precio: 10,
      paraCanje: true,
      unidadesMayoreo: 5,
    ),
  ],
);

class SaleTestRef implements Ref {
  final sink = TicketSink();
  SesionState session = testSesion;
  SaleMode mode = SaleMode.createVenta;
  @override
  T watch<T>(ProviderListenable<T> p) => read(p);
  @override
  T read<T>(ProviderListenable<T> provider) {
    if (identical(provider, sesionProvider)) return session as T;
    if (identical(provider, ticketProvider)) {
      return TicketProvider(ticket: sink.ticket, mode: mode) as T;
    }
    if (identical(provider, ticketProvider.notifier)) return sink as T;
    throw UnimplementedError();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProductsSaleState initial(
  TicketDetail line, {
  bool incIgv = true,
  String moneda = 'PEN',
}) => ProductsSaleState(
  productsSales: [line],
  currencies: [
    Currency(codigoMoneda: 'PEN', tipoCambio: 1),
    Currency(codigoMoneda: 'USD', tipoCambio: 4),
  ],
  currency: Currency(codigoMoneda: moneda, tipoCambio: moneda == 'PEN' ? 1 : 4),
  isLoading: false,
  isBarcodeSearching: false,
  error: null,
  pageNumber: 0,
  paginacion: true,
  perPage: 20,
  sortField: 'id',
  sortOrder: 1,
  filterGlobal: '',
  idPuntoVenta: 1,
  incIgv: incIgv,
  tipoComprobante: 'NV',
  otrosTributos: null,
  porcentajeDescuentoGlobal: null,
  flagRetencion: false,
  porcentajeRetencion: 0,
  codigoTipoOperacion: '0101',
);

class SaleHarness extends StateNotifier<ProductsSaleState>
    with ProductsSaleNotifierSettersMixin {
  @override
  final SaleTestRef ref = SaleTestRef();
  SaleHarness(super.state);
  ProductsSaleState get snapshot => state;
}

class TicketSink implements TicketNotifier {
  Ticket ticket = Ticket(tipoComprobante: 'NV');
  @override
  void updateTicket(Ticket value) {
    ticket = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TicketDetail testLine({String moneda = 'PEN'}) => TicketDetail(
  producto: product,
  codigoTipoAfectacionIgv: '10',
  cantidad: 1,
  precioVentaUnitario: moneda == 'PEN' ? 28 : 7,
  valorUnitario: (moneda == 'PEN' ? 28 : 7) / 1.18,
  precioCompraUnitario: moneda == 'PEN' ? 3.5 : 0.875,
  montoOriginal: 28,
  monedaOriginal: 'PEN',
  devolvioEnvase: false,
  prestamoEnvase: false,
);
