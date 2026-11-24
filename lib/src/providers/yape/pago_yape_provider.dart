import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/yape/pago_yape.dart';
import 'package:teki_app/src/data/repositories/pago_yape_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/pago_yape_repository.dart';

class PagoYapeListState {
  final List<PagoYape> pagos;
  final bool loading;
  final int page;
  final bool hasMore;
  final int totalElements;
  final String? errorMessage;

  const PagoYapeListState({
    this.pagos = const [],
    this.loading = false,
    this.page = 0,
    this.hasMore = true,
    this.totalElements = 0,
    this.errorMessage,
  });

  PagoYapeListState copyWith({
    List<PagoYape>? pagos,
    bool? loading,
    int? page,
    bool? hasMore,
    int? totalElements,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PagoYapeListState(
      pagos: pagos ?? this.pagos,
      loading: loading ?? this.loading,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      totalElements: totalElements ?? this.totalElements,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class PagoYapeListNotifier extends StateNotifier<PagoYapeListState> {
  final PagoYapeRepository _repository;
  static const _perPage = 20;
  int _requestSequence = 0;

  PagoYapeListNotifier(this._repository) : super(const PagoYapeListState());

  Future<void> loadFirstPage() async {
    final sequence = ++_requestSequence;
    state = state.copyWith(loading: true, page: 0, clearError: true);
    try {
      final response = await _repository.getPagos(
        pageNumber: 0,
        perPage: _perPage,
      );
      if (sequence != _requestSequence) return;
      state = state.copyWith(
        pagos: response.content,
        loading: false,
        page: response.number,
        hasMore: !response.last,
        totalElements: response.totalElements,
        clearError: true,
      );
    } catch (error) {
      if (sequence != _requestSequence) return;
      state = state.copyWith(loading: false, errorMessage: _cleanError(error));
    }
  }

  Future<void> loadMore() async {
    if (state.loading || !state.hasMore) return;
    final sequence = ++_requestSequence;
    final nextPage = state.page + 1;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final response = await _repository.getPagos(
        pageNumber: nextPage,
        perPage: _perPage,
      );
      if (sequence != _requestSequence) return;
      state = state.copyWith(
        pagos: [...state.pagos, ...response.content],
        loading: false,
        page: response.number,
        hasMore: !response.last,
        totalElements: response.totalElements,
        clearError: true,
      );
    } catch (error) {
      if (sequence != _requestSequence) return;
      state = state.copyWith(loading: false, errorMessage: _cleanError(error));
    }
  }

  Future<void> refresh() => loadFirstPage();

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

final pagoYapeListProvider =
    StateNotifierProvider.autoDispose<PagoYapeListNotifier, PagoYapeListState>(
      (ref) => PagoYapeListNotifier(PagoYapeRepositoryImpl()),
    );
