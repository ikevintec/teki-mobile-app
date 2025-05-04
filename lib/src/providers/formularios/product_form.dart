import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:teki_app/src/data/models/company.dart';
import 'package:teki_app/src/data/models/currency.dart';
import 'package:teki_app/src/data/models/product.dart';
import 'package:teki_app/src/data/models/productPrice.dart';
import 'package:teki_app/src/data/models/unitCode.dart';

final productFormProvider =
    StateNotifierProvider<ProductFormNotifier, ProductFormState>((ref) {
  return ProductFormNotifier();
});

class ProductFormNotifier extends StateNotifier<ProductFormState> {
  ProductFormNotifier()
      : super(ProductFormState(
          nombre: '',
          unidad: UnitCode(),
          unidadCompra: UnitCode(),
          unidadAlternativa: UnitCode(),
          moneda: 'PEN',
          factor: 1,
          igv: true,
          validacionLote: false,
          tipoLote: 'Lote',
          tipoProducto: 'Articulo',
          preciosVenta: [
            ProductPrice(
              tipoPrecio: 'POR_DEFECTO',
              precio: 0.0,
              fecha: DateTime.now(),
              precioNeto: 0.0,
              margenUtilidad: 0.0,
              nombre: 'Por defecto',
              unidadesMayoreo: null,
            )
          ],
          preciosPorPuntoVenta: false,
          precioCompraNeto: 0.0,
          precioCompraIncImp: true,
          precioCompra: 0.0,
          mostrarEnWeb: false,
          mostrarEnRestaurante: false,
          favorito: false,
          empresa: Company(),
          currencies: [],
          unidades: [],
          imagenUrl: '',
          imagenFile: null,
        ));

  void setNombre(String nombre) {
    state = state.copyWith(nombre: nombre);
  }

  void setUnidad(String unidad) {
    state = state.copyWith(
        unidad: state.unidades.firstWhere(
            (element) => (element.descripcion!).trim() == unidad.trim()));
    setFactorValue();
  }

  void setUnidadAlternativa(String unidad) {
    state = state.copyWith(
        unidadAlternativa: state.unidades.firstWhere(
            (element) => (element.descripcion!).trim() == unidad.trim()));
    setFactorValue();
  }

  void setUnidadCompra(String unidad) {
    state = state.copyWith(
        unidadCompra: state.unidades.firstWhere(
            (element) => (element.descripcion!).trim() == unidad.trim()));
    setFactorValue();
  }

  void setMoneda(String moneda) {
    state = state.copyWith(moneda: moneda);
  }

  void setFactor(double factor) {
    state = state.copyWith(factor: factor);
  }

  void setIgv(bool igv) {
    state = state.copyWith(igv: igv);
  }

  void setValidacionLote(bool validacionLote) {
    state = state.copyWith(validacionLote: validacionLote);
  }

  void setTipoLote(String tipoLote) {
    state = state.copyWith(tipoLote: tipoLote);
  }

  void setTipoProducto(String tipoProducto) {
    state = state.copyWith(tipoProducto: tipoProducto);
  }

  void setPreciosVenta(List<ProductPrice> preciosVenta) {
    state = state.copyWith(preciosVenta: preciosVenta);
  }

  void setPreciosPorPuntoVenta(bool preciosPorPuntoVenta) {
    state = state.copyWith(preciosPorPuntoVenta: preciosPorPuntoVenta);
  }

  void setPrecioCompraNeto(double precioCompraNeto) {
    state = state.copyWith(precioCompraNeto: precioCompraNeto);
  }

  void setPrecioCompraIncImp(bool precioCompraIncImp) {
    state = state.copyWith(precioCompraIncImp: precioCompraIncImp);
  }

  void setPrecioCompra(double precioCompra) {
    state = state.copyWith(precioCompra: precioCompra);
  }

  void setMostrarEnWeb(bool mostrarEnWeb) {
    state = state.copyWith(mostrarEnWeb: mostrarEnWeb);
  }

  void setMostrarEnRestaurante(bool mostrarEnRestaurante) {
    state = state.copyWith(mostrarEnRestaurante: mostrarEnRestaurante);
  }

  void setFavorito(bool favorito) {
    state = state.copyWith(favorito: favorito);
  }

  void setEmpresa(Company empresa) {
    state = state.copyWith(empresa: empresa);
  }

  void setImagenFile(XFile? imagenFile) {
    state = state.copyWith(imagenFile: imagenFile);
  }

  void setImagenUrl(String imagenUrl) {
    state = state.copyWith(imagenUrl: imagenUrl);
  }

  void setFactorValue() {
    if (state.unidadCompra.descripcion == state.unidad.descripcion) {
      state = state.copyWith(
        factor: 1,
      );
    }
  }

  ProductPrice getPrecioVenta(int index) {
    if (index >= 0 && index < state.preciosVenta.length) {
      return state.preciosVenta[index];
    } else {
      throw Exception('Index out of range');
    }
  }

  void addNewPrice() {
    state = state.copyWith(
      preciosVenta: [
        ...state.preciosVenta,
        ProductPrice(
          tipoPrecio: 'POR_DEFECTO',
          precio: 0.0,
          fecha: DateTime.now(),
          precioNeto: 0.0,
          margenUtilidad: 0.0,
          nombre: 'Por defecto',
          unidadesMayoreo: null,
        )
      ],
    );
  }

  void removePrice(int index) {
    if (state.preciosVenta.length > 1) {
      state = state.copyWith(
        preciosVenta: [
          ...state.preciosVenta.sublist(0, index),
          ...state.preciosVenta.sublist(index + 1),
        ],
      );
    }
  }

  void modifyPrecioVenta(
      int index, ProductPrice Function(ProductPrice) updateFn) {
    final updatedList = [...state.preciosVenta];
    if (index >= 0 && index < updatedList.length) {
      ProductPrice updatedItem = updateFn(updatedList[index]);
      if ( updatedItem.tipoPrecio == 'ESPECIAL') {
        updatedItem = updatedItem.copyWith(nombre: '');
      }
      if (updatedItem.tipoPrecio == 'MAYOREO') {
        updatedItem = updatedItem.copyWith(nombre: 'Mayoreo');
      }
      if (updatedItem.tipoPrecio == 'POR_DEFECTO') {
        updatedItem = updatedItem.copyWith(nombre: 'Por defecto');
      }
      updatedList[index] = updatedItem;
      state = state.copyWith(preciosVenta: updatedList);
    }
  }

  void loadDataFromProduct(
      Product product, List<Currency> currencies, List<UnitCode> unidades) {
    try {
      state = state.copyWith(
        currencies: currencies,
        unidades: unidades,
      ); // Reset image file
      state = state.copyWith(
        nombre: product.nombre ?? '',
        unidadCompra: product.unidadCompra ?? state.unidades[0],
        unidad: product.unidad ?? state.unidades[0],
        unidadAlternativa: product.unidadAlternativa ?? state.unidades[0],
        moneda: product.moneda ?? 'PEN',
        factor: product.factor ?? 1,
        igv: product.igv ?? true,
        validacionLote: product.validacionLote ?? false,
        tipoLote: product.tipoLote ?? 'Lote',
        tipoProducto: product.tipoProducto ?? 'ARTICULO',
        preciosVenta: product.preciosVenta ??
            [
              ProductPrice(
                tipoPrecio: 'POR_DEFECTO',
                precio: 0.0,
                fecha: DateTime.now(),
                precioNeto: 0.0,
                margenUtilidad: 0.0,
                nombre: 'Por defecto',
                unidadesMayoreo: null,
              )
            ],
        preciosPorPuntoVenta: product.preciosPorPuntoVenta ?? false,
        precioCompraNeto: product.precioCompraNeto ?? 0.0,
        precioCompraIncImp: product.precioCompraIncImp ?? true,
        precioCompra: product.precioCompra ?? 0.0,
        mostrarEnWeb: product.mostrarEnWeb ?? false,
        mostrarEnRestaurante: product.mostrarEnRestaurante ?? false,
        favorito: product.favorito ?? false,
        empresa: product.empresa ?? Company(),
        imagenUrl: product.imagenUrl ?? '',
      );
    } catch (e) {
      print('Error loading product data: $e');
    }
  }

  // Add other setters as needed
}

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
  final String imagenUrl;
  final XFile? imagenFile;

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
    required this.imagenUrl,
    required this.imagenFile,
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
    String? imagenUrl,
    XFile? imagenFile,
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
      imagenUrl: imagenUrl ?? this.imagenUrl,
      imagenFile: imagenFile ?? this.imagenFile,
    );
  }
}
