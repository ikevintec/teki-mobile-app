import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_page.dart';

class LoyaltyPageState<T> {
  final List<T> items;
  final int total;
  final bool loaded;
  final int page;
  final String filter;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final String? error;
  const LoyaltyPageState({
    this.loaded = false,
    this.items = const [],
    this.total = 0,
    this.page = 0,
    this.filter = '',
    this.loading = false,
    this.loadingMore = false,
    this.hasMore = false,
    this.error,
  });
}

typedef LoyaltyPageLoader<T> =
    Future<LoyaltyPage<T>> Function(
      int page,
      String filter,
      CancelToken cancelToken,
    );

/// Cada instancia pertenece a una empresa y tarjeta/inscripción concretas.
class LoyaltyPageNotifier<T> extends StateNotifier<LoyaltyPageState<T>> {
  final LoyaltyPageLoader<T> loader;
  final bool enabled;
  CancelToken? _cancel;
  Timer? _debounce;
  int _version = 0;

  LoyaltyPageNotifier({required this.loader, required this.enabled})
    : super(LoyaltyPageState<T>());

  void search(String filter) {
    if (!mounted || !enabled) return;
    _debounce?.cancel();
    _cancel?.cancel();
    _version++;
    state = LoyaltyPageState<T>(filter: filter, loading: true);
    _debounce = Timer(const Duration(milliseconds: 350), () => load());
  }

  Future<void> load() => _request(more: false);
  Future<void> loadMore() => _request(more: true);

  Future<void> _request({required bool more}) async {
    if (!mounted ||
        !enabled ||
        (more && (state.loading || state.loadingMore || !state.hasMore))) {
      return;
    }
    _debounce?.cancel();
    _cancel?.cancel();
    final version = ++_version;
    final token = _cancel = CancelToken();
    final previous = state;
    final page = more ? state.page + 1 : 0;
    final filter = state.filter;
    state = more
        ? LoyaltyPageState<T>(
            loaded: previous.loaded,
            items: previous.items,
            total: previous.total,
            page: previous.page,
            filter: filter,
            hasMore: previous.hasMore,
            loadingMore: true,
          )
        : LoyaltyPageState<T>(filter: filter, loading: true);
    try {
      final result = await loader(page, filter.trim(), token);
      if (!mounted || version != _version) return;
      state = LoyaltyPageState<T>(
        loaded: true,
        items: [if (more) ...previous.items, ...result.items],
        total: result.total,
        page: page,
        filter: filter,
        hasMore: result.hasMore,
      );
    } catch (error) {
      if (!mounted || version != _version) return;
      state = LoyaltyPageState<T>(
        loaded: more && previous.loaded,
        items: more ? previous.items : [],
        total: more ? previous.total : 0,
        page: more ? previous.page : 0,
        filter: filter,
        hasMore: more && previous.hasMore,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cancel?.cancel();
    _version++;
    super.dispose();
  }
}
