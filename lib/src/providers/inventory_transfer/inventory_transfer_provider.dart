import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/response/inventory_transfer_response.dart';
import 'package:teki_app/src/data/models/teki_model/inventory_transfer.dart';
import 'package:teki_app/src/data/repositories/inventory_transfer_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/inventory_transfer_repository.dart';

final inventoryTransferRepositoryProvider =
    Provider<InventoryTransferRepository>((ref) {
      return InventoryTransferRepositoryImpl();
    });

final inventoryTransferProvider =
    StateNotifierProvider.autoDispose<
      InventoryTransferNotifier,
      InventoryTransferState
    >((ref) {
      return InventoryTransferNotifier(
        repository: ref.watch(inventoryTransferRepositoryProvider),
      );
    });

class InventoryTransferNotifier extends StateNotifier<InventoryTransferState> {
  final InventoryTransferRepository repository;
  int _requestVersion = 0;

  InventoryTransferNotifier({required this.repository})
    : super(const InventoryTransferState());

  Future<void> refresh(
    int idPuntoVenta, {
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final requestVersion = ++_requestVersion;
    state = InventoryTransferState(
      isLoading: true,
      idPuntoVenta: idPuntoVenta,
      perPage: state.perPage,
      desde: desde,
      hasta: hasta,
    );
    try {
      final response = await repository.getTransfers(
        _buildParams(
          idPuntoVenta: idPuntoVenta,
          pageNumber: 0,
          desde: desde,
          hasta: hasta,
        ),
      );
      if (requestVersion != _requestVersion) return;
      state = _stateFromResponse(
        response,
        items: response.content,
        idPuntoVenta: idPuntoVenta,
        desde: desde,
        hasta: hasta,
      );
    } catch (error) {
      if (requestVersion != _requestVersion) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading ||
        state.last ||
        state.idPuntoVenta == null ||
        state.desde == null ||
        state.hasta == null) {
      return;
    }
    final requestVersion = _requestVersion;
    final nextPage = state.pageNumber + 1;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await repository.getTransfers(
        _buildParams(
          idPuntoVenta: state.idPuntoVenta!,
          pageNumber: nextPage,
          desde: state.desde!,
          hasta: state.hasta!,
        ),
      );
      if (requestVersion != _requestVersion) return;
      state = _stateFromResponse(
        response,
        items: [...state.items, ...response.content],
        idPuntoVenta: state.idPuntoVenta!,
        desde: state.desde!,
        hasta: state.hasta!,
      );
    } catch (error) {
      if (requestVersion != _requestVersion) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: _cleanError(error),
      );
    }
  }

  Map<String, dynamic> _buildParams({
    required int idPuntoVenta,
    required int pageNumber,
    required DateTime desde,
    required DateTime hasta,
  }) {
    final dateFormat = DateFormat('dd-MM-yyyy');
    return {
      'desde': dateFormat.format(desde),
      'hasta': dateFormat.format(hasta),
      'idPuntoVenta': idPuntoVenta,
      'pageNumber': pageNumber,
      'perPage': state.perPage,
      'sortField': 'id',
      'sortOrder': -1,
    };
  }

  InventoryTransferState _stateFromResponse(
    InventoryTransferResponse response, {
    required List<InventoryTransfer> items,
    required int idPuntoVenta,
    required DateTime desde,
    required DateTime hasta,
  }) {
    return InventoryTransferState(
      items: items,
      isLoading: false,
      last: response.last,
      pageNumber: response.number,
      perPage: state.perPage,
      totalElements: response.totalElements,
      idPuntoVenta: idPuntoVenta,
      desde: desde,
      hasta: hasta,
    );
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
}

class InventoryTransferState {
  final List<InventoryTransfer> items;
  final bool isLoading;
  final bool last;
  final int pageNumber;
  final int perPage;
  final int totalElements;
  final int? idPuntoVenta;
  final DateTime? desde;
  final DateTime? hasta;
  final String? errorMessage;

  const InventoryTransferState({
    this.items = const [],
    this.isLoading = false,
    this.last = false,
    this.pageNumber = 0,
    this.perPage = 10,
    this.totalElements = 0,
    this.idPuntoVenta,
    this.desde,
    this.hasta,
    this.errorMessage,
  });

  InventoryTransferState copyWith({
    List<InventoryTransfer>? items,
    bool? isLoading,
    bool? last,
    int? pageNumber,
    int? perPage,
    int? totalElements,
    int? idPuntoVenta,
    DateTime? desde,
    DateTime? hasta,
    String? errorMessage,
    bool clearError = false,
  }) {
    return InventoryTransferState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      last: last ?? this.last,
      pageNumber: pageNumber ?? this.pageNumber,
      perPage: perPage ?? this.perPage,
      totalElements: totalElements ?? this.totalElements,
      idPuntoVenta: idPuntoVenta ?? this.idPuntoVenta,
      desde: desde ?? this.desde,
      hasta: hasta ?? this.hasta,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
