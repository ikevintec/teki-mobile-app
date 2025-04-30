import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/product.dart';
import 'package:teki_app/src/data/repositories/products_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/products_repository.dart';
import 'package:teki_app/src/utils/notifications.dart';

final productProvider = StateNotifierProvider.autoDispose
    .family<ProductNotifier, ProductState, int?>(
  (ref, int? id) {
    final ProductsRepository productsRepository = ProductsRepositoryImpl();
    return ProductNotifier(
      productsRepository: productsRepository,
      id: id,
    );
  },
);

class ProductNotifier extends StateNotifier<ProductState> {
  final ProductsRepository productsRepository;
  final int? id;
  ProductNotifier({required this.productsRepository, required this.id})
      : super(ProductState(isLoading: true, isError: false, product: null)) {
    if (id != null) {
      loadProduct(id!);
    } else {
      state = ProductState(isLoading: false, isError: false, product: Product());
    }
  }

  Future<void> loadProduct(int id) async {
    setLoading(true);
    try {
      Product product = await productsRepository.getProductById(id);
      setProduct(product);
    } catch (e) {
      errorNotification(e.toString());
      setProduct(Product());
      setError(true);
    } finally {
      setLoading(false);
    }
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(bool error) {
    state = state.copyWith(isError: error);
  }

  void setProduct(Product product) {
    state = state.copyWith(product: product);
  }
}

class ProductState {
  final bool? isLoading;
  final bool? isError;
  final Product? product;

  ProductState(
      {required this.isLoading, required this.isError, required this.product});

  ProductState copyWith({
    bool? isLoading,
    bool? isError,
    Product? product,
  }) {
    return ProductState(
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
      product: product ?? this.product,
    );
  }
}
