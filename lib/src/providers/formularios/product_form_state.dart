import 'package:image_picker/image_picker.dart';
import 'package:teki_app/src/data/models/teki_model/company.dart';
import 'package:teki_app/src/data/models/teki_model/currency.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/product_price.dart';
import 'package:teki_app/src/data/models/teki_model/unit_code.dart';

class ProductFormState {
  final String nombre;
  final UnitCode unidad;
  final UnitCode unidadAlternativa;
  final UnitCode unidadCompra;
  final String moneda;
  final double factor;
  final bool igv;
  final bool validacionLote;
  final String tipoLote;
  final String tipoProducto;
  final List<ProductPrice> preciosVenta;
  final bool preciosPorPuntoVenta;
  final double precioCompraNeto;
  final bool precioCompraIncImp;
  final double precioCompra;
  final bool mostrarEnWeb;
  final bool mostrarEnRestaurante;
  final bool favorito;
  final Company empresa;
  final List<Currency> currencies;
  final List<UnitCode> unidades;
  final List<ProductImageDraft> imagenes;

  /// numeroOrden de la imagen seleccionada (la que se ve en el círculo).
  /// -1 cuando no hay imágenes.
  final int imagenSeleccionadaSlot;
  final double precioCompraTemporal;
  final double precioCompraPorPieza;
  final double precioCompraNetoPorPieza;
  final String tipoAfectacion;
  final Product product;

  ProductFormState({
    required this.nombre,
    required this.unidad,
    required this.unidadCompra,
    required this.unidadAlternativa,
    required this.moneda,
    required this.factor,
    required this.igv,
    required this.validacionLote,
    required this.tipoLote,
    required this.tipoProducto,
    required this.preciosVenta,
    required this.preciosPorPuntoVenta,
    required this.precioCompraNeto,
    required this.precioCompraIncImp,
    required this.precioCompra,
    required this.mostrarEnWeb,
    required this.mostrarEnRestaurante,
    required this.favorito,
    required this.empresa,
    required this.currencies,
    required this.unidades,
    required this.imagenes,
    required this.imagenSeleccionadaSlot,
    required this.precioCompraTemporal,
    required this.precioCompraPorPieza,
    required this.precioCompraNetoPorPieza,
    required this.tipoAfectacion,
    required this.product,
  });

  ProductFormState copyWith({
    String? nombre,
    UnitCode? unidad,
    UnitCode? unidadCompra,
    UnitCode? unidadAlternativa,
    String? moneda,
    double? factor,
    bool? igv,
    bool? validacionLote,
    String? tipoLote,
    String? tipoProducto,
    List<ProductPrice>? preciosVenta,
    bool? preciosPorPuntoVenta,
    double? precioCompraNeto,
    bool? precioCompraIncImp,
    double? precioCompra,
    bool? mostrarEnWeb,
    bool? mostrarEnRestaurante,
    bool? favorito,
    Company? empresa,
    List<Currency>? currencies,
    List<UnitCode>? unidades,
    List<ProductImageDraft>? imagenes,
    int? imagenSeleccionadaSlot,
    double? precioCompraTemporal,
    double? precioCompraPorPieza,
    double? precioCompraNetoPorPieza,
    String? tipoAfectacion,
    Product? product,
  }) {
    return ProductFormState(
      nombre: nombre ?? this.nombre,
      unidad: unidad ?? this.unidad,
      unidadCompra: unidadCompra ?? this.unidadCompra,
      unidadAlternativa: unidadAlternativa ?? this.unidadAlternativa,
      moneda: moneda ?? this.moneda,
      factor: factor ?? this.factor,
      igv: igv ?? this.igv,
      validacionLote: validacionLote ?? this.validacionLote,
      tipoLote: tipoLote ?? this.tipoLote,
      tipoProducto: tipoProducto ?? this.tipoProducto,
      preciosVenta: preciosVenta ?? this.preciosVenta,
      preciosPorPuntoVenta: preciosPorPuntoVenta ?? this.preciosPorPuntoVenta,
      precioCompraNeto: precioCompraNeto ?? this.precioCompraNeto,
      precioCompraIncImp: precioCompraIncImp ?? this.precioCompraIncImp,
      precioCompra: precioCompra ?? this.precioCompra,
      mostrarEnWeb: mostrarEnWeb ?? this.mostrarEnWeb,
      mostrarEnRestaurante: mostrarEnRestaurante ?? this.mostrarEnRestaurante,
      favorito: favorito ?? this.favorito,
      empresa: empresa ?? this.empresa,
      currencies: currencies ?? this.currencies,
      unidades: unidades ?? this.unidades,
      imagenes: imagenes ?? this.imagenes,
      imagenSeleccionadaSlot:
          imagenSeleccionadaSlot ?? this.imagenSeleccionadaSlot,
      precioCompraTemporal: precioCompraTemporal ?? this.precioCompraTemporal,
      precioCompraPorPieza: precioCompraPorPieza ?? this.precioCompraPorPieza,
      precioCompraNetoPorPieza:
          precioCompraNetoPorPieza ?? this.precioCompraNetoPorPieza,
      tipoAfectacion: tipoAfectacion ?? this.tipoAfectacion,
      product: product ?? this.product,
    );
  }

  /// Imagen marcada como por defecto (la que muestra el círculo superior).
  /// Si ninguna está marcada, devuelve la primera disponible.
  ProductImageDraft? get imagenPorDefecto {
    for (final d in imagenes) {
      if (d.porDefecto) return d;
    }
    return imagenes.isNotEmpty ? imagenes.first : null;
  }

  /// Imagen actualmente seleccionada (la que muestra el círculo superior).
  /// Si el slot seleccionado ya no existe, cae a la por defecto.
  ProductImageDraft? get imagenSeleccionada {
    for (final d in imagenes) {
      if (d.numeroOrden == imagenSeleccionadaSlot) return d;
    }
    return imagenPorDefecto;
  }
}

/// Borrador de imagen manejado por el formulario. Unifica imágenes ya
/// existentes en el backend (con [id] y [url] remota) y nuevas seleccionadas
/// desde el dispositivo (con [file] y [url] apuntando al path local).
class ProductImageDraft {
  final int? id;
  final String url;
  final XFile? file;
  final int numeroOrden;
  final bool porDefecto;

  const ProductImageDraft({
    this.id,
    required this.url,
    this.file,
    required this.numeroOrden,
    required this.porDefecto,
  });

  bool get esNueva => file != null;

  ProductImageDraft copyWith({
    int? id,
    String? url,
    XFile? file,
    int? numeroOrden,
    bool? porDefecto,
  }) =>
      ProductImageDraft(
        id: id ?? this.id,
        url: url ?? this.url,
        file: file ?? this.file,
        numeroOrden: numeroOrden ?? this.numeroOrden,
        porDefecto: porDefecto ?? this.porDefecto,
      );
}
