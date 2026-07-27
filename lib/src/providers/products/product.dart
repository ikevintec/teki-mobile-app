import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/company.dart';
import 'package:teki_app/src/data/models/teki_model/currency.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/unitCode.dart';
import 'package:teki_app/src/data/repositories/company_repository_impl.dart';
import 'package:teki_app/src/data/repositories/products_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/company_repository.dart';
import 'package:teki_app/src/domain/repositories/products_repository.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/notifications.dart';

final productProvider =
    StateNotifierProvider.autoDispose<ProductNotifier, ProductState>(
  (ref) {
    final ProductsRepository productsRepository = ProductsRepositoryImpl();
    final CompanyRepository companyRepository = CompanyRepositoryImpl();
    return ProductNotifier(
      productsRepository: productsRepository,
      companyRepository: companyRepository,
      ref: ref,
    );
  },
);

class ProductNotifier extends StateNotifier<ProductState> {
  final ProductsRepository productsRepository;
  final CompanyRepository companyRepository;
  Ref ref;
  ProductNotifier(
      {required this.productsRepository, required this.companyRepository, required this.ref})
      : super(ProductState(
            isLoading: false,
            isError: false,
            product: Product(),
            currencies: [],
            unitCodes: []));

  Future<void> loadProduct(int id) async {
    setLoading(true);
    try {
      Product product = await productsRepository.getProductById(id);
      if (!mounted) return;
      setProduct(product);
    } catch (e) {
      if (!mounted) return;
      errorNotification(e.toString());
      setProduct(Product());
      setError(true);
    } finally {
      if (mounted) setLoading(false);
    }
  }
  Future<void> loadMainData() async {
    setLoading(true);
    try {
      int? idCompany = ref.watch(sesionProvider).company?.id;
      if (idCompany == null) {
        errorNotification('No hay empresa Relacionada');
        setError(true);
        return;
      }
      Company company = await companyRepository.getCompanyById(idCompany);
      if (!mounted) return;
      if (company.unidades != null && company.unidades!.isNotEmpty) {
        setUnitCodes(company.unidades!);
      } else {
        setUnitCodes([]);
      }
      List<Currency> currencies = await productsRepository.getCurrency();
      if (!mounted) return;
      setCurrencies(currencies);
    } catch (e) {
      if (!mounted) return;
      errorNotification(e.toString());
      setError(true);
    } finally {
      if (mounted) setLoading(false);
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

  void setCurrencies(List<Currency> currencies) {
    state = state.copyWith(currencies: currencies);
  }

  void setUnitCodes(List<UnitCode> unitCodes) {
    state = state.copyWith(unitCodes: unitCodes);
  }
}

class ProductState {
  final bool? isLoading;
  final bool? isError;
  final Product? product;
  final List<Currency>? currencies;
  final List<UnitCode>? unitCodes;

  ProductState(
      {required this.isLoading,
      required this.isError,
      required this.product,
      required this.currencies,
      required this.unitCodes});

  ProductState copyWith({
    bool? isLoading,
    bool? isError,
    Product? product,
    List<Currency>? currencies,
    List<UnitCode>? unitCodes,
  }) {
    return ProductState(
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
      product: product ?? this.product,
      currencies: currencies ?? this.currencies,
      unitCodes: unitCodes ?? this.unitCodes,
    );
  }
}
