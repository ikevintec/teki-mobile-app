import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/product_item_package.dart';

/// Cálculos puros del preview de una orden de producción: qué insumos consume,
/// cuánto hay en el punto de venta y el costo del lote. Sin dependencias de UI
/// para poder probarse de forma aislada.
class ProductionPreview {
  ProductionPreview._();

  /// Items de la receta que se consumen al producir (paqueteItems no eliminados).
  static List<ProductItemPackage> recetaItems(Product? product) {
    return (product?.paqueteItems ?? [])
        .where((pi) => pi.eliminado != true)
        .toList();
  }

  /// Cantidad requerida de un insumo = cantidad a producir × cantidad de receta.
  static double requerido(ProductItemPackage item, double cantidad) {
    return cantidad * (item.cantidad ?? 0);
  }

  /// Stock disponible del insumo en el punto de venta indicado.
  static double disponible(ProductItemPackage item, int? idPuntoVenta) {
    final inventarios = item.productoItem?.inventarios ?? [];
    for (final inv in inventarios) {
      if (inv.puntoVenta?.id == idPuntoVenta) {
        return inv.stock ?? 0;
      }
    }
    return 0;
  }

  static bool alcanza(ProductItemPackage item, double cantidad, int? idPuntoVenta) {
    return disponible(item, idPuntoVenta) >= requerido(item, cantidad);
  }

  /// Costo de producir una unidad = Σ (cantidad receta × costo compra insumo).
  static double costoUnitario(Product? product) {
    return recetaItems(product).fold(
        0.0,
        (sum, pi) =>
            sum + (pi.cantidad ?? 0) * (pi.productoItem?.precioCompra ?? 0));
  }

  static double costoLote(Product? product, double cantidad) {
    return costoUnitario(product) * cantidad;
  }

  /// Insumos con stock insuficiente para la cantidad a producir.
  static List<ProductItemPackage> faltantes(
      Product? product, double cantidad, int? idPuntoVenta) {
    return recetaItems(product)
        .where((pi) => !alcanza(pi, cantidad, idPuntoVenta))
        .toList();
  }
}
