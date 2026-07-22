import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/product_price.dart';
import 'package:teki_app/src/utils/price.dart';

void main() {
  final office = Office(id: 1);

  Product buildProduct({
    List<ProductPrice>? precios,
    bool igv = true,
    bool preciosPorPuntoVenta = false,
  }) {
    return Product(
      igv: igv,
      preciosPorPuntoVenta: preciosPorPuntoVenta,
      preciosVenta: precios,
    );
  }

  group('getPriceProduct', () {
    test('sin precios retorna 0', () {
      expect(getPriceProduct(buildProduct(precios: null), office, null), 0);
      expect(getPriceProduct(buildProduct(precios: []), office, null), 0);
    });

    test('retorna el precio POR_DEFECTO', () {
      final product = buildProduct(precios: [
        ProductPrice(tipoPrecio: 'POR_DEFECTO', precio: 25.0),
        ProductPrice(tipoPrecio: 'ESPECIAL', precio: 20.0),
      ]);
      expect(getPriceProduct(product, office, null), 25.0);
    });

    test('producto sin igv agrega el impuesto al precio', () {
      final product = buildProduct(
        igv: false,
        precios: [ProductPrice(tipoPrecio: 'POR_DEFECTO', precio: 100.0)],
      );
      expect(
        getPriceProduct(product, office, {'igv': 0.18}),
        closeTo(118.0, 0.001),
      );
    });

    test('mayoreo aplica el tramo correcto según cantidad', () {
      // Los tramos deben estar ordenados por unidadesMayoreo (búsqueda binaria)
      final product = buildProduct(precios: [
        ProductPrice(tipoPrecio: 'POR_DEFECTO', precio: 10.0),
        ProductPrice(tipoPrecio: 'MAYOREO', precio: 8.0, unidadesMayoreo: 10),
        ProductPrice(tipoPrecio: 'MAYOREO', precio: 6.0, unidadesMayoreo: 50),
      ]);

      // Menos que el primer tramo → precio por defecto
      expect(getPriceProduct(product, office, {'qty': 5.0}), 10.0);
      // Dentro del primer tramo
      expect(getPriceProduct(product, office, {'qty': 30.0}), 8.0);
      // Alcanza el segundo tramo (límite exacto incluido)
      expect(getPriceProduct(product, office, {'qty': 50.0}), 6.0);
      expect(getPriceProduct(product, office, {'qty': 500.0}), 6.0);
    });

    test('preciosPorPuntoVenta filtra por el punto de venta', () {
      final product = buildProduct(
        preciosPorPuntoVenta: true,
        precios: [
          ProductPrice(
              tipoPrecio: 'POR_DEFECTO', precio: 30.0, puntoVenta: Office(id: 1)),
          ProductPrice(
              tipoPrecio: 'POR_DEFECTO', precio: 99.0, puntoVenta: Office(id: 2)),
        ],
      );
      expect(getPriceProduct(product, Office(id: 1), null), 30.0);
      expect(getPriceProduct(product, Office(id: 2), null), 99.0);
      // Punto de venta sin precio asignado → 0
      expect(getPriceProduct(product, Office(id: 3), null), 0.0);
    });

    test('recargo por item se descuenta del precio (se maneja global)', () {
      final product = buildProduct(
        precios: [ProductPrice(tipoPrecio: 'POR_DEFECTO', precio: 118.0)],
      );
      // precio / (1 + igv + recargo/100) * (1 + igv)
      final expected = (118.0 / (1 + 0.18 + 0.10)) * 1.18;
      expect(
        getPriceProduct(
            product, office, {'igv': 0.18, 'porcentajeRecargoPorItem': 10.0}),
        closeTo(expected, 0.001),
      );
    });

    test('recargo se ignora con absolute=true', () {
      final product = buildProduct(
        precios: [ProductPrice(tipoPrecio: 'POR_DEFECTO', precio: 118.0)],
      );
      expect(
        getPriceProduct(product, office, {
          'igv': 0.18,
          'porcentajeRecargoPorItem': 10.0,
          'absolute': true,
        }),
        118.0,
      );
    });
  });
}
