import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/inventory_production.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/repositories/inventory_production_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/inventory_production_repository.dart';

// ─────────────────────────── Lista de órdenes ───────────────────────────

class ProductionListState {
  final List<InventoryProduction> orders;
  final bool loading;
  final int page;
  final bool hasMore;
  final int totalElements;

  const ProductionListState({
    this.orders = const [],
    this.loading = false,
    this.page = 0,
    this.hasMore = true,
    this.totalElements = 0,
  });

  ProductionListState copyWith({
    List<InventoryProduction>? orders,
    bool? loading,
    int? page,
    bool? hasMore,
    int? totalElements,
  }) =>
      ProductionListState(
        orders: orders ?? this.orders,
        loading: loading ?? this.loading,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        totalElements: totalElements ?? this.totalElements,
      );
}

class ProductionListNotifier extends StateNotifier<ProductionListState> {
  final InventoryProductionRepository _repo;
  static const _perPage = 15;

  ProductionListNotifier(this._repo) : super(const ProductionListState());

  Future<void> loadFirstPage() async {
    state = state.copyWith(loading: true);
    try {
      final res = await _repo.getProductions({
        'pageNumber': '0',
        'perPage': '$_perPage',
        'sortField': 'fecha',
        'sortOrder': '0',
      });
      state = state.copyWith(
        orders: res.content,
        loading: false,
        page: 0,
        hasMore: !res.last,
        totalElements: res.totalElements,
      );
    } catch (_) {
      state = state.copyWith(loading: false);
      rethrow;
    }
  }

  Future<void> loadMore() async {
    if (state.loading || !state.hasMore) return;
    final next = state.page + 1;
    state = state.copyWith(loading: true);
    try {
      final res = await _repo.getProductions({
        'pageNumber': '$next',
        'perPage': '$_perPage',
        'sortField': 'fecha',
        'sortOrder': '0',
      });
      state = state.copyWith(
        orders: [...state.orders, ...res.content],
        loading: false,
        page: next,
        hasMore: !res.last,
        totalElements: res.totalElements,
      );
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> refresh() => loadFirstPage();

  Future<void> voidOrder(int id) async {
    await _repo.voidProduction(id);
    await loadFirstPage();
  }
}

final inventoryProductionListProvider =
    StateNotifierProvider<ProductionListNotifier, ProductionListState>(
        (ref) => ProductionListNotifier(InventoryProductionRepositoryImpl()));

// ─────────────────────────── Formulario de creación ───────────────────────────

class ProductionFormItem {
  final Product product;
  final double cantidad;
  final double? cantidadAlternativa;

  const ProductionFormItem({
    required this.product,
    this.cantidad = 1,
    this.cantidadAlternativa,
  });

  ProductionFormItem copyWith({double? cantidad, double? cantidadAlternativa}) =>
      ProductionFormItem(
        product: product,
        cantidad: cantidad ?? this.cantidad,
        cantidadAlternativa: cantidadAlternativa ?? this.cantidadAlternativa,
      );
}

class ProductionFormState {
  final List<ProductionFormItem> items;
  final String observacion;
  final bool submitting;

  const ProductionFormState({
    this.items = const [],
    this.observacion = '',
    this.submitting = false,
  });

  ProductionFormState copyWith({
    List<ProductionFormItem>? items,
    String? observacion,
    bool? submitting,
  }) =>
      ProductionFormState(
        items: items ?? this.items,
        observacion: observacion ?? this.observacion,
        submitting: submitting ?? this.submitting,
      );
}

class ProductionFormNotifier extends StateNotifier<ProductionFormState> {
  final InventoryProductionRepository _repo;

  ProductionFormNotifier(this._repo) : super(const ProductionFormState());

  bool addProduct(Product product) {
    if (state.items.any((it) => it.product.id == product.id)) {
      return false; // ya agregado
    }
    state = state.copyWith(items: [...state.items, ProductionFormItem(product: product)]);
    return true;
  }

  void removeAt(int index) {
    final list = [...state.items]..removeAt(index);
    state = state.copyWith(items: list);
  }

  void setCantidad(int index, double cantidad) {
    final list = [...state.items];
    list[index] = list[index].copyWith(cantidad: cantidad);
    state = state.copyWith(items: list);
  }

  void setCantidadAlternativa(int index, double? cantidad) {
    final list = [...state.items];
    list[index] = list[index].copyWith(cantidadAlternativa: cantidad);
    state = state.copyWith(items: list);
  }

  void setObservacion(String value) =>
      state = state.copyWith(observacion: value);

  void reset() => state = const ProductionFormState();

  Future<void> submit(int idPuntoVenta) async {
    state = state.copyWith(submitting: true);
    try {
      await _repo.saveProduction({
        'idPuntoVenta': idPuntoVenta,
        'observacion': state.observacion.trim().isEmpty ? null : state.observacion.trim(),
        'producciones': state.items
            .map((it) => {
                  'idProducto': it.product.id,
                  'cantidad': it.cantidad,
                  'cantidadAlternativa': it.cantidadAlternativa,
                })
            .toList(),
      });
      state = const ProductionFormState();
    } catch (e) {
      state = state.copyWith(submitting: false);
      rethrow;
    }
  }
}

final productionFormProvider = StateNotifierProvider.autoDispose<
        ProductionFormNotifier, ProductionFormState>(
    (ref) => ProductionFormNotifier(InventoryProductionRepositoryImpl()));
