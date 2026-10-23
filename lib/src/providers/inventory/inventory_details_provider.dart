import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/response/inventory_detail_page.dart';
import 'package:teki_app/src/data/models/teki_model/batch_product.dart';
import 'package:teki_app/src/data/models/teki_model/inventory_record.dart';
import 'package:teki_app/src/data/repositories/inventory_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/inventory_repository.dart';

final inventoryDetailRepositoryProvider = Provider<InventoryRepository>(
  (ref) => InventoryRepositoryImpl(),
);

final inventoryBatchesProvider = StateNotifierProvider.autoDispose
    .family<
      InventoryDetailsNotifier<BatchProduct>,
      InventoryDetailsState<BatchProduct>,
      int
    >((ref, idInventory) {
      final repository = ref.watch(inventoryDetailRepositoryProvider);
      return InventoryDetailsNotifier<BatchProduct>(
        fetch: (page, size, token) => repository.getInventoryBatches(
          idInventory,
          page,
          size,
          cancelToken: token,
        ),
      )..loadNextPage();
    });

final inventoryBatchRecordsProvider = StateNotifierProvider.autoDispose
    .family<
      InventoryDetailsNotifier<InventoryRecord>,
      InventoryDetailsState<InventoryRecord>,
      int
    >((ref, idBatch) {
      final repository = ref.watch(inventoryDetailRepositoryProvider);
      return InventoryDetailsNotifier<InventoryRecord>(
        fetch: (page, size, token) =>
            repository.getBatchRecords(idBatch, page, size, cancelToken: token),
      )..loadNextPage();
    });

class InventoryDetailsState<T> {
  final List<T> items;
  final bool isLoading;
  final bool last;
  final int nextPage;
  final String? error;

  const InventoryDetailsState({
    this.items = const [],
    this.isLoading = false,
    this.last = false,
    this.nextPage = 0,
    this.error,
  });
}

/// Comparte paginación, reintento y cancelación entre lotes y sus movimientos.
class InventoryDetailsNotifier<T>
    extends StateNotifier<InventoryDetailsState<T>> {
  final Future<InventoryDetailPage<T>> Function(int, int, CancelToken) fetch;
  final int perPage;
  CancelToken? _cancelToken;

  InventoryDetailsNotifier({required this.fetch, this.perPage = 15})
    : super(InventoryDetailsState<T>());

  Future<void> loadNextPage() async {
    if (!mounted || state.isLoading || state.last) return;
    final previous = state;
    final token = _cancelToken = CancelToken();
    state = InventoryDetailsState(
      items: previous.items,
      nextPage: previous.nextPage,
      isLoading: true,
    );
    try {
      final response = await fetch(previous.nextPage, perPage, token);
      if (!mounted || token.isCancelled) return;
      state = InventoryDetailsState(
        items: [...previous.items, ...response.items],
        nextPage: previous.nextPage + 1,
        last: response.last,
      );
    } catch (_) {
      if (!mounted || token.isCancelled) return;
      // No avanzar página tras un error: el reintento recupera los mismos datos.
      state = InventoryDetailsState(
        items: previous.items,
        nextPage: previous.nextPage,
        error: 'No se pudo cargar la información. Intenta nuevamente.',
      );
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel('Detalle de inventario cerrado');
    super.dispose();
  }
}
