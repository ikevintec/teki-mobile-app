import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:teki_app/src/data/models/teki_model/config.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/ticket_detail.dart';
import 'package:teki_app/src/providers/sale/products/helpers/ticket_detail_helper.dart';
import '../support/envase_sale_fixture.dart';
import 'package:teki_app/src/data/models/teki_model/product_price.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';

void main() {
  final originalDebugPrint = debugPrint;
  setUp(() => debugPrint = (String? message, {int? wrapWidth}) {});
  tearDown(() => debugPrint = originalDebugPrint);
  for (final moneda in ['PEN', 'USD']) {
    for (final incIgv in [true, false]) {
      test(
        'agregar retornables separa modalidades sin reconvertir costos: $moneda IGV=$incIgv',
        () {
          final divisor = moneda == 'PEN' ? 1 : 4;
          final h = SaleHarness(
            initial(
              testLine(moneda: moneda),
              moneda: moneda,
              incIgv: incIgv,
            ),
          );
          addTearDown(h.dispose);
          h.setModoEnvase(0, ModoEnvase.canje);
          h.setCantidadProductSale(0, 2);
          h.setPrecioProductSale(0, 11 / divisor / (incIgv ? 1 : 1.18));
          final before = h.snapshot.productsSales.first;
          final added = product.copyWith(precioCompra: 17.5);
          h.setProductsSales(added, null);
          expect(h.snapshot.productsSales, hasLength(2));
          h.setModoEnvase(1, ModoEnvase.prestamo);
          h.setCantidadProductSale(1, 3);
          h.setProductsSales(added, null);
          expect(h.snapshot.productsSales, hasLength(3));
          h.setModoEnvase(2, ModoEnvase.venta);
          final rows = h.snapshot.productsSales;
          expect(rows.first.precioVentaUnitario, before.precioVentaUnitario);
          expect(rows.first.precioManual, isTrue);
          expect(rows.map((r) => r.cantidad), [2, 3, 1]);
          expect(rows.map((r) => r.prestamoEnvase == true), [
            false,
            true,
            false,
          ]);
          expect(rows.map((r) => r.devolvioEnvase == true), [
            true,
            false,
            false,
          ]);
          expect(rows[0].precioCompraUnitario, closeTo(3.5 / divisor, 1e-9));
          expect(rows[1].precioCompraUnitario, closeTo(17.5 / divisor, 1e-9));
          expect(rows[2].precioCompraUnitario, closeTo(17.5 / divisor, 1e-9));
          expect(h.ref.sink.ticket.totalVenta, closeTo(86 / divisor, 1e-9));
          h.setProductsSales(added, 1);
          expect(h.snapshot.productsSales, hasLength(3));
          expect(h.snapshot.productsSales[1].cantidad, 4);
          expect(
            h.snapshot.productsSales.first.precioVentaUnitario,
            before.precioVentaUnitario,
          );
        },
      );
    }
  }
  for (final reason in [
    'empresa',
    'producto',
    'vinculo',
    'cotizacion',
    'editarCotizacion',
  ]) {
    test(
      'agregar repetido sigue sumando cuando no aplica retorno: $reason',
      () {
        var item = product;
        if (reason == 'producto') {
          item = product.copyWith(envaseRetornable: false);
        }
        if (reason == 'vinculo') {
          item = Product(id: 1, moneda: 'PEN', envaseRetornable: true);
        }
        final h = SaleHarness(initial(testLine().copyWith(producto: item)));
        addTearDown(h.dispose);
        if (reason == 'empresa') {
          h.ref.session = testSesion.copyWith(
            config: ConfigCompany(
              permitirRetornoEnvase: false,
              igv: .18,
              porcentajeRecargoPorItem: 0,
            ),
          );
        }
        if (reason == 'cotizacion') h.ref.mode = SaleMode.createCotizacion;
        if (reason == 'editarCotizacion') h.ref.mode = SaleMode.editCotizacion;
        h.setProductsSales(item, null);
        expect(h.snapshot.productsSales, hasLength(1));
        expect(h.snapshot.productsSales.single.cantidad, 2);
      },
    );
  }
  for (final moneda in ['PEN', 'USD']) {
    for (final incIgv in [true, false]) {
      test(
        'modos, cantidades y tarifa automática cuadran en $moneda, IGV incluido=$incIgv',
        () {
          final h = SaleHarness(
            initial(
              testLine(moneda: moneda),
              incIgv: incIgv,
              moneda: moneda,
            ),
          );
          addTearDown(h.dispose);
          final divisor = moneda == 'PEN' ? 1 : 4;
          for (final modo in [
            ModoEnvase.prestamo,
            ModoEnvase.venta,
            ModoEnvase.canje,
            ModoEnvase.prestamo,
          ]) {
            h.setModoEnvase(0, modo);
            final esperado = (modo == ModoEnvase.venta ? 28 : 12) / divisor;
            expect(
              h.snapshot.productsSales.single.precioVentaUnitario,
              closeTo(esperado, 1e-9),
            );
            expect(
              h.snapshot.productsSales.single.valorUnitario,
              closeTo(esperado / 1.18, 1e-9),
            );
            expect(h.ref.sink.ticket.totalVenta, closeTo(esperado, 1e-9));
            expect(
              h.snapshot.productsSales.single.precioCompraUnitario,
              closeTo(3.5 / divisor, 1e-9),
            );
          }
          h.setCantidadProductSale(0, 5);
          expect(h.ref.sink.ticket.totalVenta, closeTo(50 / divisor, 1e-9));
          final precioManual = (11 / divisor) / (incIgv ? 1 : 1.18);
          h.setPrecioProductSale(0, precioManual);
          h.setModoEnvase(0, ModoEnvase.venta);
          h.setCantidadProductSale(0, 2);
          expect(h.ref.sink.ticket.totalVenta, closeTo(22 / divisor, 1e-9));
          h.restablecerPrecioEnvase(0);
          expect(h.ref.sink.ticket.totalVenta, closeTo(56 / divisor, 1e-9));
          expect(
            h.snapshot.productsSales.single.precioCompraUnitario,
            closeTo(3.5 / divisor, 1e-9),
          );
        },
      );
    }
  }

  test(
    'cambiar o restablecer envase no reconvierte costos ni precios de otras líneas USD',
    () {
      final otra = TicketDetail(
        producto: Product(id: 3, moneda: 'PEN', igv: true),
        codigoTipoAfectacionIgv: '10',
        cantidad: 1,
        precioVentaUnitario: 10,
        valorUnitario: 10 / 1.18,
        precioCompraUnitario: 5,
        montoOriginal: 40,
        monedaOriginal: 'PEN',
      );
      final h = SaleHarness(
        initial(testLine(moneda: 'USD'), moneda: 'USD').copyWith(
          productsSales: [
            testLine(moneda: 'USD'),
            otra,
          ],
        ),
      );
      addTearDown(h.dispose);
      for (final modo in [
        ModoEnvase.prestamo,
        ModoEnvase.venta,
        ModoEnvase.canje,
      ]) {
        h.setModoEnvase(0, modo);
        h.restablecerPrecioEnvase(0);
        expect(h.snapshot.productsSales[1].precioCompraUnitario, 5);
        expect(h.snapshot.productsSales[1].precioVentaUnitario, 10);
        expect(h.snapshot.productsSales[0].precioCompraUnitario, 0.875);
      }
      h.setCantidadProductSale(0, 3);
      expect(h.snapshot.productsSales[1].precioCompraUnitario, 5);
      expect(h.ref.sink.ticket.totalVenta, closeTo(19, 1e-9));
    },
  );

  test(
    'línea exonerada no recibe IGV al cambiar modo con valores sin impuesto',
    () {
      final h = SaleHarness(
        initial(
          testLine().copyWith(codigoTipoAfectacionIgv: '20'),
          incIgv: false,
        ),
      );
      addTearDown(h.dispose);
      h.setModoEnvase(0, ModoEnvase.prestamo);
      expect(h.snapshot.productsSales.single.valorUnitario, closeTo(12, 1e-9));
      expect(h.ref.sink.ticket.totalVenta, closeTo(12, 1e-9));
      expect(h.ref.sink.ticket.totalIgv, 0);
    },
  );
  test(
    'sin flag, producto sin configurar y cotización no cambian modalidad ni precio',
    () {
      final h = SaleHarness(initial(testLine()));
      addTearDown(h.dispose);
      h.ref.session = testSesion.copyWith(
        config: ConfigCompany(permitirRetornoEnvase: false),
      );
      final before = h.snapshot;
      h.setModoEnvase(0, ModoEnvase.prestamo);
      h.restablecerPrecioEnvase(0);
      expect(h.snapshot, same(before));
      h.ref.session = testSesion;
      h.ref.mode = SaleMode.createCotizacion;
      h.setModoEnvase(0, ModoEnvase.prestamo);
      expect(h.snapshot, same(before));
      final normal = SaleHarness(
        initial(testLine().copyWith(producto: Product(id: 4))),
      );
      addTearDown(normal.dispose);
      final original = normal.snapshot;
      normal.setModoEnvase(0, ModoEnvase.prestamo);
      normal.restablecerPrecioEnvase(0);
      expect(normal.snapshot, same(original));
    },
  );

  test(
    'tarifa de catálogo sin IGV mantiene total final al cambiar modo y cantidad',
    () {
      final catalogo = product.copyWith(
        igv: false,
        preciosVenta: [
          ProductPrice(tipoPrecio: 'POR_DEFECTO', precio: 28 / 1.18),
          ProductPrice(
            tipoPrecio: 'ESPECIAL',
            precio: 12 / 1.18,
            paraCanje: true,
          ),
        ],
      );
      final h = SaleHarness(
        initial(testLine().copyWith(producto: catalogo), incIgv: false),
      );
      addTearDown(h.dispose);
      h.setModoEnvase(0, ModoEnvase.prestamo);
      h.setCantidadProductSale(0, 2);
      expect(h.ref.sink.ticket.totalVenta, closeTo(24, 1e-9));
    },
  );

  test(
    'cantidad sincronizada desde formulario usa mayoreo en moneda de venta sin cambiar costos',
    () {
      final h = SaleHarness(
        initial(testLine(moneda: 'USD'), incIgv: false, moneda: 'USD'),
      );
      addTearDown(h.dispose);
      h.setModoEnvase(0, ModoEnvase.prestamo);
      h.syncAllProductsFromForms([
        {'quantity': 5, 'price': 3 / 1.18, 'description': 'Bidón'},
      ]);
      expect(h.ref.sink.ticket.totalVenta, closeTo(12.5, 1e-9));
      expect(h.snapshot.productsSales.single.precioCompraUnitario, 0.875);
    },
  );
}
