import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/response/products.dart';
import 'package:teki_app/src/data/repositories/products_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/products_repository.dart';
import 'package:teki_app/src/utils/query_params_builders.dart';

final productsProvider = StateNotifierProvider.autoDispose<ProductsNotifier, ProductsState>(
  (ref) {
    final ProductsRepository productsRepository = ProductsRepositoryImpl();
    return ProductsNotifier(
      productsRepository: productsRepository,
      ref: ref,
    );
  },
);

class ProductsNotifier extends StateNotifier<ProductsState> {
  final ProductsRepository productsRepository;
  final Ref ref;
  ProductsNotifier({
    required this.productsRepository,
    required this.ref,
  }) : super(ProductsState(
          products: [],
          isLoading: true,
          last: false,
          paginacion: true,
          pageNumber: 0,
          perPage: 10,
          sortOrder: 1,
          sortField: 'id',
          filterGlobal: '',
          codigo: null,
          codigoBarra: null,
          nombre: null,
          tipo: null,
          idMarca: null,
          codigoMoneda: null,
          idCategoria: null,
          mostrarEnRestaurante: null,
          mostrarEnWeb: null,
          favorito: null,
          idPuntoVenta: null,
          idPuntoVentaOrder: null,
        ));
  void loadNextPage() async {
    if (state.last) return;
    setLoading(true);
    setPageNumber(state.pageNumber! + 1);
    ProductResponse response =
        await productsRepository.getProducts(buildProductQueryParams(state));
    if (!mounted) return;
    if (response.content != null || response.content!.isNotEmpty) {
      setProducts([...state.products, ...response.content!]);
    }
    setLast(response.last ?? false);

    setLoading(false);
  }

  Future<void> resetProducts() async {
    setLoading(true);
    resetFilters();
    ProductResponse response =
        await productsRepository.getProducts(buildProductQueryParams(state));
    if (!mounted) return;
    if (response.content != null || response.content!.isNotEmpty) {
      setProducts(response.content!);
    }
    setLast(response.last ?? false);
    setLoading(false);
  }

  /// Recarga la lista conservando la búsqueda activa (para volver de editar
  /// sin perder el filtro). Si no hay búsqueda, resetea a la lista completa.
  void refreshKeepingFilter() {
    final filtro = state.filterGlobal ?? '';
    if (filtro.isNotEmpty) {
      searchProducts(filtro);
    } else {
      resetProducts();
    }
  }

  void searchProducts(String search) async {
    setLoading(true);
    setPageNumber(0);
    setProducts([]);
    setFilterGlobal(search);
    ProductResponse response =
        await productsRepository.getProducts(buildProductQueryParams(state));
    if (!mounted) return;
    if (response.content != null || response.content!.isNotEmpty) {
      setProducts(response.content!);
    }
    setLast(response.last ?? false);
    setLoading(false);
  }

  void resetFilters() {
    state = state.copyWith(
      paginacion: true,
      pageNumber: 0,
      perPage: 10,
      sortOrder: 1,
      sortField: 'id',
      filterGlobal: '',
      codigo: null,
      codigoBarra: null,
      nombre: null,
      tipo: null,
      idMarca: null,
      codigoMoneda: null,
      idCategoria: null,
      mostrarEnRestaurante: null,
      mostrarEnWeb: null,
      favorito: null,
      idPuntoVenta: null,
      idPuntoVentaOrder: null,
      products: [],
    );
  }

  void setFilterGlobal(String filterGlobal) {
    state = state.copyWith(filterGlobal: filterGlobal, isLoading: true);
  }

  void setProducts(List<Product> products) {
    state = state.copyWith(products: products, isLoading: false, last: false);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setLast(bool last) {
    state = state.copyWith(last: last);
  }

  void setIdPuntoVentaOrder(int idPuntoVenta) {
    state = state.copyWith(idPuntoVentaOrder: idPuntoVenta);
  }

  void setPageNumber(int pageNumber) {
    state = state.copyWith(pageNumber: pageNumber);
  }

  void setProduct(Product product) {
    state = state.copyWith(product: product);
  }
}

class ProductsState {
  final List<Product> products;
  final Product? product;
  final bool isLoading;
  final bool last;

  // Parámetros de búsqueda
  final int? pageNumber;
  final bool? paginacion;
  final int? perPage;
  final String? sortField;
  final int? sortOrder;
  final String? filterGlobal;
  final String? codigo;
  final String? codigoBarra;
  final String? nombre;
  final List<String>? tipo;
  final int? idMarca;
  final String? codigoMoneda;
  final List<int>? idCategoria;
  final bool? mostrarEnRestaurante;
  final bool? mostrarEnWeb;
  final bool? favorito;
  final int? idPuntoVenta;
  final int? idPuntoVentaOrder;
  final int? limit;

  ProductsState(
      {required this.products,
      required this.isLoading,
      required this.last,
      this.pageNumber,
      this.paginacion,
      this.perPage,
      this.sortField,
      this.sortOrder,
      this.filterGlobal,
      this.codigo,
      this.codigoBarra,
      this.nombre,
      this.tipo,
      this.idMarca,
      this.codigoMoneda,
      this.idCategoria,
      this.mostrarEnRestaurante,
      this.mostrarEnWeb,
      this.favorito,
      this.idPuntoVenta,
      this.idPuntoVentaOrder,
      this.limit,
      this.product});

  ProductsState copyWith({
    List<Product>? products,
    Product? product,
    bool? isLoading,
    bool? last,
    int? pageNumber,
    bool? paginacion,
    int? perPage,
    String? sortField,
    int? sortOrder,
    String? filterGlobal,
    String? codigo,
    String? codigoBarra,
    String? nombre,
    List<String>? tipo,
    int? idMarca,
    String? codigoMoneda,
    List<int>? idCategoria,
    bool? mostrarEnRestaurante,
    bool? mostrarEnWeb,
    bool? favorito,
    int? idPuntoVenta,
    int? idPuntoVentaOrder,
    int? limit,
  }) {
    return ProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      last: last ?? this.last,
      pageNumber: pageNumber ?? this.pageNumber,
      paginacion: paginacion ?? this.paginacion,
      perPage: perPage ?? this.perPage,
      sortField: sortField ?? this.sortField,
      sortOrder: sortOrder ?? this.sortOrder,
      filterGlobal: filterGlobal ?? this.filterGlobal,
      codigo: codigo ?? this.codigo,
      codigoBarra: codigoBarra ?? this.codigoBarra,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      idMarca: idMarca ?? this.idMarca,
      codigoMoneda: codigoMoneda ?? this.codigoMoneda,
      idCategoria: idCategoria ?? this.idCategoria,
      mostrarEnRestaurante: mostrarEnRestaurante ?? this.mostrarEnRestaurante,
      mostrarEnWeb: mostrarEnWeb ?? this.mostrarEnWeb,
      favorito: favorito ?? this.favorito,
      idPuntoVenta: idPuntoVenta ?? this.idPuntoVenta,
      idPuntoVentaOrder: idPuntoVentaOrder ?? this.idPuntoVentaOrder,
      limit: limit ?? this.limit,
      product: product ?? this.product,
    );
  }
}
