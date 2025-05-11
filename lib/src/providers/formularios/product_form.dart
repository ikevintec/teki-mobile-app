import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:teki_app/src/data/models/company.dart';
import 'package:teki_app/src/data/models/currency.dart';
import 'package:teki_app/src/data/models/product.dart';
import 'package:teki_app/src/data/models/productPrice.dart';
import 'package:teki_app/src/data/models/unitCode.dart';
import 'package:teki_app/src/data/repositories/image_repository_impl.dart';
import 'package:teki_app/src/data/repositories/products_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/image_repository.dart';
import 'package:teki_app/src/domain/repositories/products_repository.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/products/product.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/notifications.dart';

final productFormProvider =
    StateNotifierProvider<ProductFormNotifier, ProductFormState>((ref) {
  ProductsRepository productsRepository = ProductsRepositoryImpl();
  ImageRepository imageRepository = ImageRepositoryImpl();
  return ProductFormNotifier(
      ref: ref,
      productsRepository: productsRepository,
      imageRepository: imageRepository);
});

class ProductFormNotifier extends StateNotifier<ProductFormState> {
  final Ref ref;
  final ProductsRepository productsRepository;
  final ImageRepository imageRepository;
  ProductFormNotifier(
      {required this.ref,
      required this.productsRepository,
      required this.imageRepository})
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
          tipoAfectacion: '10',
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
          precioCompraNetoPorPieza: 0.0,
          precioCompraPorPieza: 0.0,
          precioCompraIncImp: false,
          precioCompra: 0.0,
          precioCompraTemporal: 0.0,
          mostrarEnWeb: false,
          mostrarEnRestaurante: false,
          favorito: false,
          empresa: Company(),
          currencies: [],
          unidades: [],
          imagenUrl: '',
          imagenFile: null,
          product: Product(),
        ));

  void setNombre(String nombre) {
    state = state.copyWith(nombre: nombre);
  }

  void setUnidad(String unidad) {
    state = state.copyWith(
        unidad: state.unidades.firstWhere(
            (element) => (element.descripcion!).trim() == unidad.trim()));
    setFactorValue();
    changePrice();
  }

  void setUnidadAlternativa(String unidad) {
    state = state.copyWith(
        unidadAlternativa: state.unidades.firstWhere(
            (element) => (element.descripcion!).trim() == unidad.trim()));
    setFactorValue();
    changePrice();
  }

  void setUnidadCompra(String unidad) {
    state = state.copyWith(
        unidadCompra: state.unidades.firstWhere(
            (element) => (element.descripcion!).trim() == unidad.trim()));
    setFactorValue();
    changePrice();
  }

  void setMoneda(String moneda) {
    state = state.copyWith(moneda: moneda);
  }

  void setFactor(double factor) {
    state = state.copyWith(factor: factor);
    changePrice();
  }

  void setIgv(bool igv) {
    state = state.copyWith(igv: igv);
    changePrice();
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
    changePrice();
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

  void setPrecioCompraTemporal(double precioCompraTemporal) {
    state = state.copyWith(precioCompraTemporal: precioCompraTemporal);
    changePrice();
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
          tipoPrecio: '',
          precio: 0.0,
          fecha: DateTime.now(),
          precioNeto: 0.0,
          margenUtilidad: 0.0,
          nombre: '-',
          unidadesMayoreo: null,
        )
      ],
    );
    changePrice();
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

  void modifyPrecioVenta(int index,
      ProductPrice Function(ProductPrice) updateFn, bool modifyName) {
    final updatedList = [...state.preciosVenta];
    if (index >= 0 && index < updatedList.length) {
      ProductPrice updatedItem = updateFn(updatedList[index]);
      if (modifyName) {
        if (updatedItem.tipoPrecio == 'ESPECIAL') {
          updatedItem = updatedItem.copyWith(nombre: '');
        }
        if (updatedItem.tipoPrecio == 'MAYOREO') {
          updatedItem = updatedItem.copyWith(nombre: 'Mayoreo');
        }
        if (updatedItem.tipoPrecio == 'POR_DEFECTO') {
          updatedItem = updatedItem.copyWith(
              nombre: 'Por defecto', unidadesMayoreo: null);
        }
      }
      updatedItem = updatedItem.copyWith(
          margenUtilidad: getUtilidad(
              state.precioCompraPorPieza, updatedItem.precio ?? 0.0));
      updatedList[index] = updatedItem;
      state = state.copyWith(preciosVenta: updatedList);
    }
  }

  void loadDataFromProduct(Product product, List<Currency> currencies, List<UnitCode> unidades) {
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
        precioCompraTemporal: product.precioCompra ?? 0.0,
        product: product,
      );
      if (product.nombre == null ||
          product.nombre!.isEmpty ||
          product.precioCompraIncImp == null) {
        changePrice();
      }
    } catch (e) {
      print('Error loading product data: $e');
    }
  }

  double getUtilidad(double precioCompra, double precioVenta) {
    if (precioCompra == 0) {
      return 0.0;
    }
    double utilidad = ((precioVenta - precioCompra) / precioCompra) * 100;
    return utilidad;
  }

  // Add other setters as needed
  changePrice() {
    final config = ref.read(sesionProvider).config;
    final igv = state.igv;
    final igvAmount = config!.igv;
    final precioCompraIncImp = state.precioCompraIncImp;
    final precioCompraTemporal = state.precioCompraTemporal;
    final factor = state.factor;
    if (!igv) {
      state = state.copyWith(
        precioCompra: (precioCompraTemporal * (1.0 + igvAmount!)),
        precioCompraNeto: precioCompraTemporal,
      );
    } else {
      if (precioCompraIncImp) {
        state = state.copyWith(
          precioCompraNeto: (precioCompraTemporal / (1.0 + igvAmount!)),
          precioCompra: precioCompraTemporal,
        );
      } else {
        state = state.copyWith(
          precioCompraNeto: precioCompraTemporal,
          precioCompra: (precioCompraTemporal * (1.0 + igvAmount!)),
        );
      }
    }
    state = state.copyWith(
      precioCompraPorPieza: factor != 0 ? (state.precioCompra / factor) : 0.0,
      precioCompraNetoPorPieza:
          factor != 0 ? (state.precioCompraNeto / factor) : 0.0,
    );
    //iterar por los rpecios venta y actualizarles la utilidad
    for (int i = 0; i < state.preciosVenta.length; i++) {
      ProductPrice precioVenta = state.preciosVenta[i];
      double precioCompraPorPieza = state.precioCompraPorPieza;
      state = state.copyWith(
        preciosVenta: [
          ...state.preciosVenta.sublist(0, i),
          precioVenta.copyWith(
            margenUtilidad:
                getUtilidad(precioCompraPorPieza, precioVenta.precio ?? 0.0),
          ),
          ...state.preciosVenta.sublist(i + 1),
        ],
      );
    }
  }

  //imprimir el estado actual
Product formTomodel() {
  return state.product.copyWith(
    nombre: state.nombre,
    unidadCompra: state.unidadCompra,
    unidad: state.unidad,
    unidadAlternativa: state.unidadAlternativa,
    moneda: state.moneda,
    factor: state.factor,
    igv: state.igv,
    validacionLote: state.validacionLote,
    tipoLote: state.tipoLote.toUpperCase(),
    tipoProducto: state.tipoProducto,
    preciosVenta: state.preciosVenta,
    preciosPorPuntoVenta: state.preciosPorPuntoVenta,
    precioCompraNeto: state.precioCompraNeto,
    precioCompraIncImp: state.precioCompraIncImp,
    precioCompra: state.precioCompra == 0.0 ? null : state.precioCompra,
    mostrarEnWeb: state.mostrarEnWeb,
    mostrarEnRestaurante: state.mostrarEnRestaurante,
    favorito: state.favorito,
    empresa: state.empresa,
    imagenUrl: state.imagenUrl == '' || state.imagenUrl.length <= 10
        ? null
        : state.imagenUrl,
    tipoAfectacion: state.igv ? '10' : '20',
  );
}
  void loadImagen() async {
      if (state.imagenFile != null) {
        final idCompany = ref.read(sesionProvider).company!.id;
        final imageResponse = await imageRepository.getImageUrl(
            idCompany!, state.imagenFile!.path, state.imagenFile!.name);
        String url = imageResponse.url;
        state = state.copyWith(imagenUrl: url);
      }
  }

  void createProduct() async {
    ref.read(productProvider.notifier).setLoading(true); 
    try {
      loadImagen();
      Product product = formTomodel();
      await productsRepository.createProduct(product);
      successNotification('Producto creado correctamente');
      ref.read(productProvider.notifier).setLoading(false);
      Get.toNamed(AppRoutes.products);
    } catch (e) {
      errorNotification(e.toString());
      ref.read(productProvider.notifier).setLoading(false);
    }
  }

  void updateProduct() async {
    ref.read(productProvider.notifier).setLoading(true);
    try {
      loadImagen();
      Product product = formTomodel();
      await productsRepository.updateProduct(product);
      successNotification('Producto actualizado correctamente');
      ref.read(productProvider.notifier).setLoading(false);
      Get.toNamed(AppRoutes.products);
    } catch (e) {
      errorNotification(e.toString());
      ref.read(productProvider.notifier).setLoading(false);
    }
  }
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
    required this.imagenUrl,
    required this.imagenFile,
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
    String? imagenUrl,
    XFile? imagenFile,
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
      imagenUrl: imagenUrl ?? this.imagenUrl,
      imagenFile: imagenFile ?? this.imagenFile,
      precioCompraTemporal: precioCompraTemporal ?? this.precioCompraTemporal,
      precioCompraPorPieza: precioCompraPorPieza ?? this.precioCompraPorPieza,
      precioCompraNetoPorPieza:
          precioCompraNetoPorPieza ?? this.precioCompraNetoPorPieza,
      tipoAfectacion: tipoAfectacion ?? this.tipoAfectacion,
      product: product ?? this.product,
    );
  }

  @override
  String toString() {
    // TODO: implement toString
    return super.toString();
  }
}
