import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:teki_app/src/data/models/teki_model/company.dart';
import 'package:teki_app/src/data/models/teki_model/currency.dart';
import 'package:teki_app/src/data/models/teki_model/brand.dart';
import 'package:teki_app/src/data/models/teki_model/category.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/product_item_package.dart';
import 'package:teki_app/src/data/models/teki_model/product_image.dart';
import 'package:teki_app/src/data/models/teki_model/product_price.dart';
import 'package:teki_app/src/data/models/teki_model/unit_code.dart';
import 'package:teki_app/src/data/repositories/image_repository_impl.dart';
import 'package:teki_app/src/data/repositories/products_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/image_repository.dart';
import 'package:teki_app/src/domain/repositories/products_repository.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/products/product.dart';
import 'package:teki_app/src/providers/products/products.dart';
import 'package:teki_app/src/utils/notifications.dart';
import 'package:teki_app/src/providers/formularios/product_form_state.dart';

export 'package:teki_app/src/providers/formularios/product_form_state.dart';

part 'product_form_images.dart';

final productFormProvider =
    StateNotifierProvider<ProductFormNotifier, ProductFormState>((ref) {
  ProductsRepository productsRepository = ProductsRepositoryImpl();
  ImageRepository imageRepository = ImageRepositoryImpl();
  return ProductFormNotifier(
      ref: ref,
      productsRepository: productsRepository,
      imageRepository: imageRepository);
});

class ProductFormNotifier extends StateNotifier<ProductFormState>
    with ProductFormImages {
  @override
  final Ref ref;
  final ProductsRepository productsRepository;
  @override
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
          imagenes: const [],
          imagenSeleccionadaSlot: -1,
          product: Product(),
        ));

  /// Máximo de imágenes por producto (1 por defecto + 4 adicionales).
  static const int maxImagenes = 5;

  void setCodigo(String codigo) {
    state = state.copyWith(codigo: codigo);
  }

  void setCodigoBarra(String codigoBarra) {
    state = state.copyWith(codigoBarra: codigoBarra);
  }

  void setCategoria(Category? categoria) {
    // Guardamos referencia mínima: la categoría trae árbol (padre/hijas) que
    // al serializar puede volverse circular. El backend solo usa el id.
    state = state.copyWith(
      categoria: categoria == null
          ? null
          : Category(id: categoria.id, nombre: categoria.nombre),
    );
  }

  void setMarca(Brand? marca) {
    state = state.copyWith(
      marca: marca == null ? null : Brand(id: marca.id, nombre: marca.nombre),
    );
  }

  void setOcultarEnBuscadorVentas(bool value) {
    state = state.copyWith(ocultarEnBuscadorVentas: value);
  }

  void setServicio(bool servicio) {
    state = state.copyWith(servicio: servicio);
  }

  void setEnvaseRetornable(bool value) {
    state = state.copyWith(
      envaseRetornable: value,
      productoEnvase: value ? state.productoEnvase : null,
    );
  }

  void setProductoEnvase(Product? producto) {
    state = state.copyWith(productoEnvase: producto);
  }

  // ── Items del paquete (composición) ──────────────────────────────────
  bool addPaqueteItem(Product producto) {
    final actuales = state.paqueteItems
        .where((pi) => pi.eliminado != true)
        .toList();
    if (actuales.any((pi) => pi.productoItem?.id == producto.id)) {
      return false;
    }
    state = state.copyWith(paqueteItems: [
      ...state.paqueteItems,
      ProductItemPackage(productoItem: producto, cantidad: 1),
    ]);
    return true;
  }

  void setPaqueteItemCantidad(int index, double cantidad) {
    final list = [...state.paqueteItems];
    list[index].cantidad = cantidad;
    state = state.copyWith(paqueteItems: list);
  }

  void removePaqueteItem(int index) {
    final list = [...state.paqueteItems]..removeAt(index);
    state = state.copyWith(paqueteItems: list);
  }

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

  void loadDataFromProduct(
      Product product, List<Currency> currencies, List<UnitCode> unidades) {
    try {
      state = state.copyWith(
        currencies: currencies,
        unidades: unidades,
      ); // Reset image file
      state = state.copyWith(
        nombre: product.nombre ?? '',
        codigo: product.codigo ?? '',
        codigoBarra: product.codigoBarra ?? '',
        categoria: product.categoria == null
            ? null
            : Category(
                id: product.categoria!.id, nombre: product.categoria!.nombre),
        marca: product.marca == null
            ? null
            : Brand(id: product.marca!.id, nombre: product.marca!.nombre),
        servicio: product.servicio ?? false,
        ocultarEnBuscadorVentas: product.ocultarEnBuscadorVentas ?? false,
        envaseRetornable: product.envaseRetornable ?? false,
        productoEnvase: product.productoEnvase,
        paqueteItems: product.paqueteItems ?? const [],
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
        imagenes: _draftsFromProduct(product.imagenes),
        imagenSeleccionadaSlot: _slotPrincipal(_draftsFromProduct(product.imagenes)),
        precioCompraTemporal: product.precioCompra ?? 0.0,
        product: product,
      );
      //actualizar los precios venta
      for (int i = 0; i < state.preciosVenta.length; i++) {
        ProductPrice precioVenta = state.preciosVenta[i];
        state = state.copyWith(
          preciosVenta: [
            ...state.preciosVenta.sublist(0, i),
            precioVenta.copyWith(
              nombre: state.preciosVenta[i].tipoPrecio == 'ESPECIAL'
                  ? state.preciosVenta[i].nombre
                  : state.preciosVenta[i].tipoPrecio == 'MAYOREO'
                      ? 'Mayoreo'
                      : state.preciosVenta[i].tipoPrecio == 'POR_DEFECTO'
                          ? 'Por defecto'
                          : '',
            ),
            ...state.preciosVenta.sublist(i + 1),
          ],
        );
      }
      if (product.nombre == null ||
          product.nombre!.isEmpty ||
          product.precioCompraIncImp == null) {
        changePrice();
      }
    } catch (e) {
      debugPrint('Error loading product data: $e');
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
    for (int i = 0; i < state.preciosVenta.length; i++) {
      ProductPrice precioVenta = state.preciosVenta[i];
      state = state.copyWith(
        preciosVenta: [
          ...state.preciosVenta.sublist(0, i),
          precioVenta.copyWith(
            nombre: state.preciosVenta[i].tipoPrecio == 'ESPECIAL'
                ? state.preciosVenta[i].nombre
                : '',
          ),
          ...state.preciosVenta.sublist(i + 1),
        ],
      );
    }
    return state.product.copyWith(
      nombre: state.nombre,
      codigo: state.codigo,
      codigoBarra: state.codigoBarra,
      categoria: state.categoria,
      marca: state.marca,
      servicio: state.servicio,
      ocultarEnBuscadorVentas: state.ocultarEnBuscadorVentas,
      envaseRetornable: state.envaseRetornable,
      productoEnvase: state.envaseRetornable ? state.productoEnvase : null,
      paqueteItems: state.paqueteItems,
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
      imagenes: _buildImagenes(),
      tipoAfectacion: state.igv ? '10' : '20',
    );
  }

  void createProduct() async {
    ref.read(productProvider.notifier).setLoading(true);
    try {
      await loadImagen();
      Product product = formTomodel();
      await productsRepository.createProduct(product);
      ref.read(productProvider.notifier).setLoading(false);
      Get.back();
      ref.read(productsProvider.notifier).resetProducts();
      successNotification('Producto creado correctamente');
    } catch (e) {
      errorNotification(e.toString());
      ref.read(productProvider.notifier).setLoading(false);
    }
  }

  void updateProduct() async {
    ref.read(productProvider.notifier).setLoading(true);
    try {
      await loadImagen();
      Product product = formTomodel();
      debugPrint('🖼️ imagenes enviadas (update): '
          '${product.imagenes?.map((e) => 'id=${e.id} orden=${e.numeroOrden} '
              'def=${e.porDefecto} elim=${e.eliminado}').toList()}');
      await productsRepository.updateProduct(product);
      ref.read(productProvider.notifier).setLoading(false);
      Get.back();
      ref.read(productsProvider.notifier).refreshKeepingFilter();
      successNotification('Producto actualizado correctamente');
    } catch (e) {
      errorNotification(e.toString());
      ref.read(productProvider.notifier).setLoading(false);
    }
  }
}
