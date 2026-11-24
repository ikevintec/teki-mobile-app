import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/response/login.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail.dart';
import 'package:teki_app/src/data/models/teki_model/config.dart';
import 'package:teki_app/src/data/models/teki_model/customer.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/product_price.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/ticket_detail.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/products/helpers/ticket_detail_helper.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';

void main() {
  SesionState sesion({
    bool retorno = true,
    bool inventario = true,
    Customer? porDefecto,
  }) => SesionState(
    login: LoginResponse(),
    office: Office(id: 1),
    roles: const ['INVENTARIO_VER'],
    config: ConfigCompany(
      igv: 0.18,
      permitirRetornoEnvase: retorno,
      inventario: inventario,
      clientePorDefectoData: porDefecto,
    ),
  );

  // Bidón: lleno 28, canje 12, canje por mayoreo (≥5) 10.
  Product bidon({bool configurado = true}) => Product(
    id: 10,
    igv: true,
    preciosPorPuntoVenta: false,
    envaseRetornable: configurado,
    productoEnvase: configurado ? Product(id: 20) : null,
    preciosVenta: [
      ProductPrice(tipoPrecio: 'POR_DEFECTO', precio: 28),
      ProductPrice(tipoPrecio: 'POR_DEFECTO', precio: 12, paraCanje: true),
      ProductPrice(
        tipoPrecio: 'MAYOREO',
        precio: 10,
        unidadesMayoreo: 5,
        paraCanje: true,
      ),
    ],
  );

  TicketProvider venta(String tipo, {SaleMode mode = SaleMode.createVenta}) =>
      TicketProvider(
        ticket: Ticket(tipoComprobante: tipo),
        mode: mode,
      );

  group('tarifa automática', () {
    test('canje usa el precio para canje y venta con envase el normal', () {
      expect(getAutomaticPrice(bidon(), sesion(), 1, conCanje: true), closeTo(12, 1e-9));
      expect(getAutomaticPrice(bidon(), sesion(), 1, conCanje: false), closeTo(28, 1e-9));
    });

    test('canje aplica el mayoreo de canje según cantidad', () {
      expect(getAutomaticPrice(bidon(), sesion(), 4, conCanje: true), closeTo(12, 1e-9));
      expect(getAutomaticPrice(bidon(), sesion(), 5, conCanje: true), closeTo(10, 1e-9));
    });

    test('sin flag de empresa el producto conserva su precio habitual', () {
      final s = sesion(retorno: false);
      expect(productoConEnvase(bidon(), s), isFalse);
      expect(getAutomaticPrice(bidon(), s, 1, conCanje: true), closeTo(28, 1e-9));
    });
  });

  group('alta y cantidad', () {
    test('al agregar en venta viene en canje con su tarifa', () {
      final td = getTicketDetail(product: bidon(), sesion: sesion());
      expect(td.devolvioEnvase, isTrue);
      expect(td.precioVentaUnitario, closeTo(12, 1e-9));
      expect(modoEnvase(td), ModoEnvase.canje);
    });

    test('en cotización no hay canje ni tarifa de canje', () {
      final td = getTicketDetail(
        product: bidon(),
        sesion: sesion(),
        isQuotation: true,
      );
      expect(td.devolvioEnvase, isNull);
      expect(td.precioVentaUnitario, closeTo(28, 1e-9));
    });

    test('el préstamo usa la tarifa de canje al cambiar cantidad', () {
      final td = TicketDetail(
        producto: bidon(),
        cantidad: 1,
        prestamoEnvase: true,
        devolvioEnvase: false,
      );
      final updated = changeQtyTicketDetail(
        ticketDetail: td,
        quantity: 5,
        sesion: sesion(),
      );
      expect(updated.precioVentaUnitario, closeTo(10, 1e-9));
    });

    test('un precio manual se conserva al cambiar la cantidad', () {
      final td = TicketDetail(
        producto: bidon(),
        cantidad: 1,
        devolvioEnvase: true,
        precioVentaUnitario: 11,
        precioManual: true,
      );
      final updated = changeQtyTicketDetail(
        ticketDetail: td,
        quantity: 2,
        sesion: sesion(),
      );
      expect(updated.cantidad, 2);
      expect(updated.precioVentaUnitario, closeTo(11, 1e-9));
    });
  });

  group('préstamo', () {
    test('solo en factura, boleta o nota de venta con inventario', () {
      for (final tipo in ['01', '03', 'NV']) {
        expect(puedePrestarEnvase(venta(tipo), sesion(), const []), isTrue);
      }
      expect(
        puedePrestarEnvase(
          venta('CO', mode: SaleMode.createCotizacion),
          sesion(),
          const [],
        ),
        isFalse,
      );
      expect(
        puedePrestarEnvase(venta('NV'), sesion(inventario: false), const []),
        isFalse,
      );
    });

    test('no en cuentas de restaurante', () {
      final lines = [TicketDetail(comandaDetalle: CommandDetail())];
      expect(puedePrestarEnvase(venta('NV'), sesion(), lines), isFalse);
    });

    test('exige cliente registrado distinto del cliente por defecto', () {
      final porDefecto = Customer(id: 1, numeroDocumento: '00000000');
      final s = sesion(porDefecto: porDefecto);
      expect(clienteRegistradoParaEnvase(null, s), isFalse);
      expect(
        clienteRegistradoParaEnvase(
          Customer(id: 1, numeroDocumento: '00000000'),
          s,
        ),
        isFalse,
      );
      expect(
        clienteRegistradoParaEnvase(Customer(id: 2, numeroDocumento: ''), s),
        isFalse,
      );
      expect(
        clienteRegistradoParaEnvase(
          Customer(id: 3, numeroDocumento: '45678912'),
          s,
        ),
        isTrue,
      );
    });
  });

  test('resumen en singular y plural', () {
    expect(
      resumenEnvase(TicketDetail(cantidad: 1, devolvioEnvase: true)),
      'Ingresa 1 vacío al entregar.',
    );
    expect(
      resumenEnvase(TicketDetail(cantidad: 3, devolvioEnvase: true)),
      'Ingresan 3 vacíos al entregar.',
    );
    expect(
      resumenEnvase(TicketDetail(cantidad: 2, prestamoEnvase: true)),
      '2 envases por devolver.',
    );
    expect(
      resumenEnvase(TicketDetail(cantidad: 2)),
      'El precio incluye el envase.',
    );
  });
}
