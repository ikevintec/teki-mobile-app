import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:teki_app/src/data/models/teki_model/company.dart';
import 'package:teki_app/src/data/models/teki_model/currency.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
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
          imagenes: const [],
          imagenSeleccionadaSlot: -1,
          product: Product(),
        ));

  /// Máximo de imágenes por producto (1 por defecto + 4 adicionales).
  static const int maxImagenes = 5;

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

  /// numeroOrden de la imagen por defecto (o -1 si no hay imágenes).
  int _slotPrincipal(List<ProductImageDraft> imgs) {
    for (final d in imgs) {
      if (d.porDefecto) return d.numeroOrden;
    }
    return imgs.isNotEmpty ? imgs.first.numeroOrden : -1;
  }

  /// Reasigna `numeroOrden` = posición para mantener las imágenes siempre
  /// contiguas y en orden, y garantiza que exista exactamente una por defecto.
  List<ProductImageDraft> _normalizar(List<ProductImageDraft> imgs) {
    final hayDefault = imgs.any((d) => d.porDefecto);
    return [
      for (int i = 0; i < imgs.length; i++)
        imgs[i].copyWith(
          numeroOrden: i,
          porDefecto: hayDefault ? imgs[i].porDefecto : i == 0,
        ),
    ];
  }

  /// Agrega una imagen nueva (archivo local) al final de la lista y la deja
  /// seleccionada. La primera imagen del producto se marca automáticamente
  /// como por defecto; las siguientes no.
  void addImagen(String path, XFile? file) {
    if (state.imagenes.length >= maxImagenes) return;
    final nuevos = _normalizar([
      ...state.imagenes,
      ProductImageDraft(
        url: path,
        file: file,
        numeroOrden: state.imagenes.length,
        porDefecto: state.imagenes.isEmpty,
      ),
    ]);
    state = state.copyWith(
      imagenes: nuevos,
      imagenSeleccionadaSlot: nuevos.length - 1,
    );
  }

  /// Cambia la posición de una imagen (arrastrar en la tira). Reasigna el
  /// `numeroOrden` según el nuevo orden y conserva cuál está seleccionada.
  void reordenarImagenes(int oldIndex, int newIndex) {
    final imgs = [...state.imagenes];
    if (oldIndex < 0 || oldIndex >= imgs.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    if (newIndex < 0) newIndex = 0;
    if (newIndex >= imgs.length) newIndex = imgs.length - 1;

    final seleccionada = state.imagenSeleccionadaSlot;
    final movido = imgs.removeAt(oldIndex);
    imgs.insert(newIndex, movido);
    // Nueva posición del que estaba seleccionado (numeroOrden aún original).
    final idxSel = imgs.indexWhere((d) => d.numeroOrden == seleccionada);
    state = state.copyWith(
      imagenes: _normalizar(imgs),
      imagenSeleccionadaSlot: idxSel >= 0 ? idxSel : seleccionada,
    );
  }

  /// Marca qué imagen está seleccionada (la que se muestra en el círculo).
  void setImagenSeleccionada(int numeroOrden) {
    state = state.copyWith(imagenSeleccionadaSlot: numeroOrden);
  }

  /// Elimina la imagen del slot indicado. Las restantes se recompactan (sin
  /// huecos) y se garantiza una por defecto. Ajusta también la selección.
  void removeImagen(int numeroOrden) {
    final restantes = state.imagenes
        .where((d) => d.numeroOrden != numeroOrden)
        .toList();
    int nuevoSel;
    if (state.imagenSeleccionadaSlot == numeroOrden) {
      nuevoSel = restantes.isNotEmpty ? 0 : -1;
    } else {
      final idx = restantes
          .indexWhere((d) => d.numeroOrden == state.imagenSeleccionadaSlot);
      nuevoSel = idx >= 0 ? idx : (restantes.isNotEmpty ? 0 : -1);
    }
    state = state.copyWith(
      imagenes: _normalizar(restantes),
      imagenSeleccionadaSlot: nuevoSel,
    );
  }

  /// Marca la imagen del slot indicado como la por defecto (desmarca el resto).
  void setImagenPorDefecto(int numeroOrden) {
    state = state.copyWith(
      imagenes: state.imagenes
          .map((d) => d.copyWith(porDefecto: d.numeroOrden == numeroOrden))
          .toList(),
    );
  }

  /// Reemplaza (o crea) la imagen actualmente seleccionada. Lo usa el círculo
  /// superior: al elegir una nueva foto sustituye la seleccionada; con `path`
  /// vacío la quita. Si aún no hay imágenes, crea la primera (por defecto).
  void setImagenSeleccionadaFile(String path, XFile? file) {
    if (path.isEmpty) {
      final sel = state.imagenSeleccionada;
      if (sel != null) removeImagen(sel.numeroOrden);
      return;
    }
    final imgs = [...state.imagenes];
    final idx =
        imgs.indexWhere((d) => d.numeroOrden == state.imagenSeleccionadaSlot);
    if (idx >= 0) {
      imgs[idx] = ProductImageDraft(
        url: path,
        file: file,
        numeroOrden: imgs[idx].numeroOrden,
        porDefecto: imgs[idx].porDefecto,
      );
      state = state.copyWith(imagenes: imgs);
    } else {
      addImagen(path, file);
    }
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

  /// Convierte las `imagenes` del producto (backend) en borradores editables.
  /// Solo conserva las no eliminadas, limita a [maxImagenes] y normaliza el
  /// `numeroOrden` a la posición (0..n) para mapear a los slots de la UI.
  /// Garantiza que exista exactamente una imagen por defecto.
  List<ProductImageDraft> _draftsFromProduct(List<ProductImage>? imgs) {
    if (imgs == null) return const [];
    final activas = imgs.where((i) => i.eliminado != true).toList()
      ..sort((a, b) => (a.numeroOrden ?? 0).compareTo(b.numeroOrden ?? 0));
    final visibles = activas.take(maxImagenes).toList();
    final tieneDefault = visibles.any((i) => i.porDefecto == true);
    final drafts = <ProductImageDraft>[];
    for (int i = 0; i < visibles.length; i++) {
      final img = visibles[i];
      drafts.add(ProductImageDraft(
        id: img.id,
        url: img.imagen ?? '',
        numeroOrden: i,
        porDefecto: tieneDefault ? (img.porDefecto == true) : i == 0,
      ));
    }
    return drafts;
  }

  /// Construye el campo `imagenes` (lista) que espera el API a partir de los
  /// borradores actuales (ya con URL resuelta en [loadImagen]):
  /// - Cada imagen conservada o nueva se envía con su `numeroOrden` y su
  ///   marca `porDefecto` (solo una es `true`).
  /// - Las imágenes que existían en el backend y ya no están en el form se
  ///   envían con `eliminado: true` (conservando su `id`).
  List<ProductImage> _buildImagenes() {
    final existentes = state.product.imagenes ?? [];
    final actuales = state.imagenes;
    final idsActuales =
        actuales.map((d) => d.id).where((id) => id != null).toSet();

    final result = <ProductImage>[];

    // Imágenes del backend que ya no están en el form: marcarlas eliminadas.
    for (final img in existentes) {
      if (img.id != null &&
          img.eliminado != true &&
          !idsActuales.contains(img.id)) {
        result.add(img.copyWith(eliminado: true));
      }
    }

    // Imágenes actuales (conservadas o nuevas).
    for (final d in actuales) {
      result.add(ProductImage(
        id: d.id,
        imagen: d.url,
        numeroOrden: d.numeroOrden,
        porDefecto: d.porDefecto,
        eliminado: false,
      ));
    }

    return result;
  }

  /// Sube las imágenes nuevas (las que tienen archivo local) y reemplaza su
  /// URL local por la remota devuelta por el backend.
  Future<void> loadImagen() async {
    if (!state.imagenes.any((d) => d.file != null)) return;
    final idCompany = ref.read(sesionProvider).company!.id;
    final actualizadas = <ProductImageDraft>[];
    for (final d in state.imagenes) {
      if (d.file != null) {
        final imageResponse = await imageRepository.getImageUrl(
            idCompany!, d.file!.path, d.file!.name);
        actualizadas.add(ProductImageDraft(
          id: null,
          url: imageResponse.url,
          numeroOrden: d.numeroOrden,
          porDefecto: d.porDefecto,
        ));
      } else {
        actualizadas.add(d);
      }
    }
    state = state.copyWith(imagenes: actualizadas);
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
      print('🖼️ imagenes enviadas (update): '
          '${product.imagenes?.map((e) => 'id=${e.id} orden=${e.numeroOrden} '
              'def=${e.porDefecto} elim=${e.eliminado}').toList()}');
      await productsRepository.updateProduct(product);
      ref.read(productProvider.notifier).setLoading(false);
      Get.back();
      ref.read(productsProvider.notifier).resetProducts();
      successNotification('Producto actualizado correctamente');
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

  @override
  String toString() {
    // TODO: implement toString
    return super.toString();
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
