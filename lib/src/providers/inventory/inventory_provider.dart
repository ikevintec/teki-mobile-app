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

  Future<void> loadInventory(int idPuntoVenta) async {
    final requestVersion = ++_requestVersion;
    state = InventoryState(
      items: [],
      isLoading: true,
      last: false,
      pageNumber: 0,
      perPage: state.perPage,
      sortField: state.sortField,
      sortOrder: state.sortOrder,
      filterGlobal: null,
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
        last: response.last ?? false,
        isLoading: false,
      );
    } catch (_) {
      if (!mounted) return;
      if (requestVersion != _requestVersion) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sin conexi\u00f3n',
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.last || state.isLoading) return;
    final requestVersion = _requestVersion;
    state = state.copyWith(isLoading: true, pageNumber: state.pageNumber + 1);
    final requestState = state;
    try {
      final response = await inventoryRepository
          .getInventory(buildInventoryQueryParams(state));
      if (!mounted) return;
          .getInventory(buildInventoryQueryParams(requestState));
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
      );
    }
  }

  Future<void> searchInventory(
    String search, {
    int? idPuntoVenta,
  }) async {
    final targetOfficeId = idPuntoVenta ?? state.idPuntoVenta;
    if (targetOfficeId == null || targetOfficeId <= 0) return;
    if (search.isEmpty) {
      await loadInventory(targetOfficeId);
      return;
    }
    final requestVersion = ++_requestVersion;
    state = InventoryState(
      items: [],
      isLoading: true,
      last: false,
      pageNumber: 0,
      perPage: state.perPage,
      sortField: state.sortField,
      sortOrder: state.sortOrder,
      filterGlobal: search,
      idPuntoVenta: targetOfficeId,
      errorMessage: null,
    );
    final requestState = state;
    try {
      final response = await inventoryRepository
          .getInventory(buildInventoryQueryParams(state));
      if (!mounted) return;
          .getInventory(buildInventoryQueryParams(requestState));
      if (requestVersion != _requestVersion) return;
      state = state.copyWith(
        items: response.content ?? [],
        last: response.last ?? false,
        isLoading: false,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: 'Sin conexión');
      if (requestVersion != _requestVersion) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sin conexión',
      );
    }
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
        errorMessage: errorMessage ?? this.errorMessage,
      );
}
