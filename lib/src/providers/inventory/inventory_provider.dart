import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';
import 'package:teki_app/src/data/repositories/inventory_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/inventory_repository.dart';
import 'package:teki_app/src/utils/query_params_builders.dart';

final inventoryProvider =
    StateNotifierProvider.autoDispose<InventoryNotifier, InventoryState>(
  (ref) => InventoryNotifier(
    inventoryRepository: InventoryRepositoryImpl(),
  ),
);

enum InventoryStockFilter { todos, bajo, agotado }

class InventoryNotifier extends StateNotifier<InventoryState> {
  final InventoryRepository inventoryRepository;
  int _requestVersion = 0;

  InventoryNotifier({required this.inventoryRepository})
      : super(InventoryState(
          items: [],
          isLoading: true,
          last: false,
          pageNumber: 0,
          perPage: 10,
          sortField: 'id',
          sortOrder: 1,
          filterGlobal: null,
          idPuntoVenta: null,
          errorMessage: null,
        ));

  Future<void> loadInventory(
    int idPuntoVenta, {
    String? search,
    InventoryStockFilter? stockFilter,
  }) async {
    final requestVersion = ++_requestVersion;
    state = InventoryState(
      items: [],
      isLoading: true,
      last: false,
      pageNumber: 0,
      perPage: state.perPage,
      sortField: state.sortField,
      sortOrder: state.sortOrder,
      filterGlobal: search?.isNotEmpty == true ? search : null,
      stockFilter: stockFilter ?? (state.idPuntoVenta == idPuntoVenta
          ? state.stockFilter : InventoryStockFilter.todos),
      idPuntoVenta: idPuntoVenta,
      errorMessage: null,
    );
    final requestState = state;
    try {
      final response = await inventoryRepository
          .getInventory(buildInventoryQueryParams(requestState));
      if (!mounted) return;
      if (requestVersion != _requestVersion) return;
      state = state.copyWith(
        items: response.content ?? [],
        totalElements: response.totalElements ?? 0,
        last: response.last ?? false,
        isLoading: false,
      );
    } catch (_) {
      if (!mounted) return;
      if (requestVersion != _requestVersion) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo cargar el inventario. Reintenta.',
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.last || state.isLoading) return;
    final requestVersion = _requestVersion;
    state = state.copyWith(isLoading: true, pageNumber: state.pageNumber + 1, clearError: true);
    final requestState = state;
    try {
      final response = await inventoryRepository
          .getInventory(buildInventoryQueryParams(requestState));
      if (!mounted) return;
      if (requestVersion != _requestVersion) return;
      state = state.copyWith(
        items: [...state.items, ...?response.content],
        last: response.last ?? false,
        isLoading: false,
      );
    } catch (_) {
      if (!mounted) return;
      if (requestVersion != _requestVersion) return;
      state = state.copyWith(
        isLoading: false,
        pageNumber: state.pageNumber - 1,
        errorMessage: 'No se pudo cargar la siguiente página. Reintenta.',
      );
    }
  }

  Future<void> searchInventory(
    String search, {
    int? idPuntoVenta,
  }) async {
    final targetOfficeId = idPuntoVenta ?? state.idPuntoVenta;
    if (targetOfficeId == null || targetOfficeId <= 0) return;
    await loadInventory(targetOfficeId, search: search);
  }

  Future<void> setStockFilter(InventoryStockFilter filter) async {
    final officeId = state.idPuntoVenta;
    if (officeId == null || filter == state.stockFilter) return;
    await loadInventory(officeId, search: state.filterGlobal, stockFilter: filter);
  }
}

class InventoryState {
  final List<Inventory> items;
  final bool isLoading;
  final bool last;
  final int pageNumber;
  final int perPage;
  final String sortField;
  final int sortOrder;
  final String? filterGlobal;
  final int? idPuntoVenta;
  final String? errorMessage;
  final InventoryStockFilter stockFilter;
  final int totalElements;

  InventoryState({
    required this.items,
    required this.isLoading,
    required this.last,
    required this.pageNumber,
    required this.perPage,
    required this.sortField,
    required this.sortOrder,
    required this.filterGlobal,
    required this.idPuntoVenta,
    required this.errorMessage,
    this.stockFilter = InventoryStockFilter.todos,
    this.totalElements = 0,
  });

  InventoryState copyWith({
    List<Inventory>? items,
    bool? isLoading,
    bool? last,
    int? pageNumber,
    int? perPage,
    String? sortField,
    int? sortOrder,
    String? filterGlobal,
    int? idPuntoVenta,
    String? errorMessage,
    InventoryStockFilter? stockFilter,
    int? totalElements,
    bool clearError = false,
  }) =>
      InventoryState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        last: last ?? this.last,
        pageNumber: pageNumber ?? this.pageNumber,
        perPage: perPage ?? this.perPage,
        sortField: sortField ?? this.sortField,
        sortOrder: sortOrder ?? this.sortOrder,
        filterGlobal: filterGlobal ?? this.filterGlobal,
        idPuntoVenta: idPuntoVenta ?? this.idPuntoVenta,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
        stockFilter: stockFilter ?? this.stockFilter,
        totalElements: totalElements ?? this.totalElements,
      );
}
