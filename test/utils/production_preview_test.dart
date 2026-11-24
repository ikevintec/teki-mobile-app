import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/product_item_package.dart';
import 'package:teki_app/src/utils/production_preview.dart';

/// Insumo con stock en el punto de venta [pvId] y costo de compra.
ProductItemPackage _insumo(String nombre, double recetaQty, double stock,
    double costo, int pvId) {
  return ProductItemPackage(
    cantidad: recetaQty,
    productoItem: Product(
      id: 1,
      nombre: nombre,
      precioCompra: costo,
      inventarios: [Inventory(puntoVenta: Office(id: pvId), stock: stock)],
    ),
  );
}

void main() {
  const pv = 1;

  // Bidón lleno = 1 vacío (costo 14, stock 20) + 1 agua (costo 3.5, stock 8).
  Product bidonLleno() => Product(
        id: 100,
        nombre: 'Bidón lleno',
        tipoProducto: 'PAQUETE_PRODUCIDO',
        paqueteItems: [
          _insumo('Bidón vacío', 1, 20, 14, pv),
          _insumo('Agua', 1, 8, 3.5, pv),
        ],
      );

  group('ProductionPreview', () {
    test('costo unitario = suma de insumos (14 + 3.5 = 17.5)', () {
      expect(ProductionPreview.costoUnitario(bidonLleno()), 17.5);
    });

    test('costo del lote = unitario × cantidad (10 → 175)', () {
      expect(ProductionPreview.costoLote(bidonLleno(), 10), 175);
    });

    test('requerido = cantidad × receta', () {
      final receta = ProductionPreview.recetaItems(bidonLleno());
      expect(ProductionPreview.requerido(receta.first, 10), 10);
    });

    test('disponible lee el stock del punto de venta', () {
      final receta = ProductionPreview.recetaItems(bidonLleno());
      expect(ProductionPreview.disponible(receta[0], pv), 20); // vacío
      expect(ProductionPreview.disponible(receta[1], pv), 8); // agua
      expect(ProductionPreview.disponible(receta[0], 999), 0); // otro PV
    });

    test('produciendo 10: el agua (stock 8) no alcanza, el vacío sí', () {
      final faltantes = ProductionPreview.faltantes(bidonLleno(), 10, pv);
      expect(faltantes.length, 1);
      expect(faltantes.first.productoItem?.nombre, 'Agua');
    });

    test('produciendo 8: todo alcanza', () {
      expect(ProductionPreview.faltantes(bidonLleno(), 8, pv), isEmpty);
    });

    test('recetaItems ignora los eliminados', () {
      final p = Product(paqueteItems: [
        _insumo('Vigente', 1, 5, 1, pv),
        ProductItemPackage(cantidad: 1, eliminado: true, productoItem: Product(id: 2)),
      ]);
      expect(ProductionPreview.recetaItems(p).length, 1);
    });
  });
}
