import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/product_price.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/domain/distribuidor/contexto_comercial.dart';
import 'package:teki_app/src/providers/sale/products/helpers/ticket_detail_helper.dart';
import '../support/envase_sale_fixture.dart';

const tipos = [
  {
    'id': 1,
    'nombre': 'Minorista',
    'categoria': 'POR_DEFECTO',
    'principal': true,
    'estado': true,
  },
  {'id': 2, 'nombre': 'Mayorista', 'categoria': 'MAYOREO', 'estado': true},
];
final articulo = Product(
  id: 7,
  nombre: 'Artículo QA',
  moneda: 'PEN',
  igv: true,
  tipoAfectacion: '10',
  precioCompra: 40,
  preciosPorPuntoVenta: false,
  preciosVenta: [
    ProductPrice(id: 1, tipoPrecio: 'POR_DEFECTO', precio: 100),
    ProductPrice(id: 2, tipoPrecio: 'MAYOREO', precio: 80, unidadesMayoreo: 5),
    ProductPrice(
      id: 3,
      tipoPrecio: 'POR_DEFECTO',
      tipoComercialId: 1,
      precio: 110,
    ),
    ProductPrice(
      id: 4,
      tipoPrecio: 'MAYOREO',
      tipoComercialId: 2,
      precio: 90,
      unidadesMayoreo: 5,
    ),
  ],
);

SaleHarness venta({
  required bool comercial,
  required bool manual,
  required bool incIgv,
  String moneda = 'PEN',
  double descuentoGlobal = 0,
}) {
  final sesion = testSesion.copyWith(
    comercial: ContextoComercial(
      activo: comercial,
      mayoreoManual: manual,
      cabecera: comercial ? 1 : null,
      tipos: tipos,
    ),
  );
  final linea = getTicketDetail(product: articulo, sesion: sesion);
  final divisor = moneda == 'USD' ? 4 : 1;
  final h = SaleHarness(
    initial(
      linea.copyWith(
        precioVentaUnitario: linea.precioVentaUnitario! / divisor,
        valorUnitario: linea.precioVentaUnitario! / divisor / 1.18,
        precioCompraUnitario: 40 / divisor,
      ),
      incIgv: incIgv,
      moneda: moneda,
    ).copyWith(porcentajeDescuentoGlobal: descuentoGlobal),
  );
  h.ref.session = sesion;
  h.ref.sink.ticket = Ticket(
    tipoComprobante: 'NV',
    tipoPrecioCabeceraId: comercial ? 1 : null,
  );
  h.calculoTotal();
  return h;
}

void main() {
  test(
    'regular cero creado al apagar comerciales no toma el precio comercial',
    () {
      final producto = articulo.copyWith(
        preciosVenta: [
          ProductPrice(id: 30, tipoPrecio: 'POR_DEFECTO', precio: 0),
          ProductPrice(
            id: 31,
            tipoPrecio: 'POR_DEFECTO',
            tipoComercialId: 1,
            precio: 110,
          ),
        ],
      );
      final linea = getTicketDetail(
        product: producto,
        sesion: testSesion.copyWith(comercial: const ContextoComercial()),
      );
      expect(linea.precioVentaUnitario, 0);
      expect(linea.tipoComercialId, isNull);
    },
  );

  for (final incIgv in [true, false]) {
    for (final comercial in [false, true]) {
      test(
        'descuento global se mantiene al cambiar cantidad: comercial=$comercial incIgv=$incIgv',
        () {
          final h = venta(
            comercial: comercial,
            manual: false,
            incIgv: incIgv,
            descuentoGlobal: 10,
          );
          addTearDown(h.dispose);
          h.setCantidadProductSale(0, 5);
          expect(
            h.ref.sink.ticket.totalVenta,
            closeTo((comercial ? 90 : 80) * 5 * .9, .00001),
          );
          expect(h.ref.sink.ticket.totalIgv, greaterThan(0));
        },
      );
    }
    test(
      'bonificaciones no se cobran ni editan desde cantidad/precio/formulario incIgv=$incIgv',
      () {
        final h = venta(comercial: true, manual: false, incIgv: incIgv);
        addTearDown(h.dispose);
        final compra = h.snapshot.productsSales.single;
        final regalo = compra.copyWith(
          esBonificacion: true,
          codigoTipoAfectacionIgv: '15',
          cantidad: 2,
          valorReferencialUnitario: 110.0,
        );
        h.setProductsSaleEntity([compra, regalo], conservarPactos: false);
        h.setCantidadProductSale(1, 20);
        h.setPrecioProductSale(1, 999);
        h.syncAllProductsFromForms([
          {
            'description': 'Compra',
            'quantity': 1,
            'price': incIgv ? compra.precioVentaUnitario : compra.valorUnitario,
          },
          {'description': 'Regalo', 'quantity': 20, 'price': 999.0},
        ]);
        expect(h.snapshot.productsSales.last.cantidad, 2);
        expect(h.snapshot.productsSales.last.esBonificacion, isTrue);
        expect(h.ref.sink.ticket.totalVenta, closeTo(110, .00001));
      },
    );
  }

  for (final comercial in [false, true]) {
    for (final incIgv in [true, false]) {
      test(
        'cantidad en USD conserva conversión y costos ajenos: comercial=$comercial incIgv=$incIgv',
        () {
          final h = venta(
            comercial: comercial,
            manual: false,
            incIgv: incIgv,
            moneda: 'USD',
          );
          addTearDown(h.dispose);
          final original = h.snapshot.productsSales.single;
          h.setProductsSaleEntity([
            original,
            original.copyWith(precioCompraUnitario: 9),
          ], conservarPactos: false);
          h.setCantidadProductSale(0, 5);
          expect(
            h.snapshot.productsSales.first.precioVentaUnitario,
            closeTo((comercial ? 90 : 80) / 4, .00001),
          );
          expect(h.snapshot.productsSales.first.precioCompraUnitario, 10);
          expect(h.snapshot.productsSales.last.precioCompraUnitario, 9);
          expect(h.snapshot.productsSales.last.cantidad, 1);
        },
      );
      test(
        'sincronizar formulario actualiza importe y neto: comercial=$comercial incIgv=$incIgv',
        () {
          final h = venta(comercial: comercial, manual: false, incIgv: incIgv);
          addTearDown(h.dispose);
          final actual = h.snapshot.productsSales.single;
          h.syncAllProductsFromForms([
            {
              'description': 'Artículo QA',
              'quantity': 5,
              'price': incIgv
                  ? actual.precioVentaUnitario
                  : actual.valorUnitario,
            },
          ]);
          expect(
            h.snapshot.productsSales.single.precioVentaUnitario,
            closeTo(comercial ? 90 : 80, .00001),
          );
          expect(
            h.ref.sink.ticket.totalVenta,
            closeTo((comercial ? 90 : 80) * 5, .00001),
          );
        },
      );
    }
  }

  for (final incIgv in [true, false]) {
    for (final comercial in [false, true]) {
      for (final manual in [false, true]) {
        test(
          'cantidad usa catálogo correcto: comercial=$comercial manual=$manual incIgv=$incIgv',
          () {
            final h = venta(
              comercial: comercial,
              manual: manual,
              incIgv: incIgv,
            );
            addTearDown(h.dispose);
            h.setCantidadProductSale(0, 5);
            final esperado = comercial ? (manual ? 110.0 : 90.0) : 80.0;
            final linea = h.snapshot.productsSales.single;
            expect(linea.precioVentaUnitario, closeTo(esperado, .00001));
            expect(h.ref.sink.ticket.totalVenta, closeTo(esperado * 5, .00001));
            expect(
              linea.tipoComercialId,
              comercial ? (manual ? 1 : 2) : isNull,
            );
            h.setCantidadProductSale(0, 1);
            expect(
              h.snapshot.productsSales.single.precioVentaUnitario,
              closeTo(comercial ? 110 : 100, .00001),
            );
          },
        );
      }
    }
    test(
      'acciones conservan tipo e importe comercial al editar cantidad incIgv=$incIgv',
      () {
        final h = venta(comercial: true, manual: false, incIgv: incIgv);
        addTearDown(h.dispose);
        h.precioComercial(0, articulo.preciosVenta!.last);
        h.setPrecioProductSale(0, incIgv ? 70 : 70 / 1.18);
        h.setCantidadProductSale(0, 2.5);
        final l = h.snapshot.productsSales.single;
        expect(l.tipoComercialId, 2);
        expect(l.origenPrecio, 'MANUAL');
        expect(l.precioVentaUnitario, closeTo(70, .00001));
        expect(h.ref.sink.ticket.totalVenta, closeTo(175, .00001));
      },
    );
    test(
      'mayoreo tradicional conserva comportamiento previo después de precio manual incIgv=$incIgv',
      () {
        final h = venta(comercial: false, manual: false, incIgv: incIgv);
        addTearDown(h.dispose);
        h.setPrecioProductSale(0, incIgv ? 70 : 70 / 1.18);
        h.setCantidadProductSale(0, 5);
        expect(
          h.snapshot.productsSales.single.precioVentaUnitario,
          closeTo(80, .00001),
        );
        expect(h.ref.sink.ticket.totalVenta, closeTo(400, .00001));
      },
    );
  }
}
