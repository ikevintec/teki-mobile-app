import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/inventory_record.dart';
import 'package:teki_app/src/data/repositories/inventory_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/inventory_repository.dart';
import 'package:teki_app/src/utils/query_params_builders.dart';

final inventoryLogsProvider = StateNotifierProvider.autoDispose
    .family<InventoryLogsNotifier, InventoryLogsState, int>(
  (ref, idInventory) => InventoryLogsNotifier(
    idInventory: idInventory,
    inventoryRepository: InventoryRepositoryImpl(),
  ),
);

class InventoryLogsNotifier extends StateNotifier<InventoryLogsState> {
  final int idInventory;
  final InventoryRepository inventoryRepository;

  InventoryLogsNotifier({
    required this.idInventory,
    required this.inventoryRepository,
  }) : super(InventoryLogsState(
          logs: [],
          isLoading: true,
          last: false,
          pageNumber: 0,
          perPage: 15,
        ));

  Future<void> loadLogs() async {
    state = state.copyWith(isLoading: true, pageNumber: 0, logs: []);
    final response = await inventoryRepository.getInventoryLogs(
      idInventory,
      buildInventoryLogsQueryParams(state),
    );
    state = state.copyWith(
      logs: response.content ?? [],
      last: response.last ?? false,
      isLoading: false,
    );
  }

  Future<void> loadNextPage() async {
    if (state.last || state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      pageNumber: state.pageNumber + 1,
    );
    final response = await inventoryRepository.getInventoryLogs(
      idInventory,
      buildInventoryLogsQueryParams(state),
    );
    state = state.copyWith(
      logs: [...state.logs, ...?response.content],
      last: response.last ?? false,
      isLoading: false,
    );
  }
}

class InventoryLogsState {
  final List<InventoryRecord> logs;
  final bool isLoading;
  final bool last;
  final int pageNumber;
  final int perPage;

  InventoryLogsState({
    required this.logs,
    required this.isLoading,
    required this.last,
    required this.pageNumber,
    required this.perPage,
  });

  InventoryLogsState copyWith({
    List<InventoryRecord>? logs,
    bool? isLoading,
    bool? last,
    int? pageNumber,
    int? perPage,
  }) =>
      InventoryLogsState(
        logs: logs ?? this.logs,
        isLoading: isLoading ?? this.isLoading,
        last: last ?? this.last,
        pageNumber: pageNumber ?? this.pageNumber,
        perPage: perPage ?? this.perPage,
      );
}
