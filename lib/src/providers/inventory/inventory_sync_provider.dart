import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/response/inventory_sync_response.dart';
import 'package:teki_app/src/data/repositories/inventory_sync_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/inventory_sync_repository.dart';

const inventorySyncMaxBatch = 200;

final inventorySyncProvider = StateNotifierProvider.autoDispose
    .family<InventorySyncNotifier, InventorySyncState, int>((ref, officeId) {
      // El listado se desmonta brevemente durante búsquedas y recargas. Este
      // margen evita repetir el resumen por esos cambios transitorios de UI.
      final keepAlive = ref.keepAlive();
      Timer? disposeTimer;
      ref.onCancel(() {
        disposeTimer = Timer(const Duration(minutes: 1), keepAlive.close);
      });
      ref.onResume(() => disposeTimer?.cancel());
      ref.onDispose(() => disposeTimer?.cancel());

      final notifier = InventorySyncNotifier(
        officeId: officeId,
        repository: InventorySyncRepositoryImpl(),
      );
      unawaited(notifier.loadBadgeOnce());
      return notifier;
    });

class InventorySyncNotifier extends StateNotifier<InventorySyncState> {
  final int officeId;
  final InventorySyncRepository repository;

  Future<void>? _badgeRequest;
  int _listRequestVersion = 0;

  InventorySyncNotifier({required this.officeId, required this.repository})
    : super(const InventorySyncState());

  /// Se ejecuta una sola vez mientras el widget permanezca montado. Las cargas
  /// y páginas del inventario principal no vuelven a consultar este resumen.
  Future<void> loadBadgeOnce() {
    return _badgeRequest ??= _loadBadge();
  }

  Future<void> _loadBadge({bool force = false}) async {
    if (!force && state.badgeLoaded) return;
    state = state.copyWith(isLoadingBadge: true, clearError: true);
    try {
      final summary = await repository.getSummary(idPuntoVenta: officeId);
      if (!mounted) return;
      state = state.copyWith(
        badgeSummary: summary,
        panelSummary: state.currentOfficeOnly && state.search.isEmpty
            ? summary
            : state.panelSummary,
        badgeLoaded: true,
        isLoadingBadge: false,
      );
    } catch (_) {
      if (!mounted) return;
      // El badge es informativo: un fallo no debe romper el inventario.
      state = state.copyWith(
        badgeLoaded: true,
        isLoadingBadge: false,
        badgeSummary: const InventorySyncSummary(),
      );
    }
  }

  /// Fuerza recargar solo el resumen/badge. Se usa al abrir el sheet (opción A)
  /// y desde el pull-to-refresh del inventario (opción B), por si se regularizó
  /// desde la web u otro dispositivo mientras la app estaba abierta.
  Future<void> refreshBadge() async {
    _badgeRequest = _loadBadge(force: true);
    await _badgeRequest;
  }

  Future<void> openPanel() async {
    await refreshBadge();
    if (!mounted) return;
    state = state.copyWith(
      currentOfficeOnly: true,
      search: '',
      selectedIds: const <int>{},
      panelSummary: state.badgeSummary,
    );
    await loadIssues(reset: true);
  }

  Future<void> setSearch(String value) async {
    final search = value.trim();
    if (search == state.search) return;
    state = state.copyWith(search: search, selectedIds: const <int>{});
    await Future.wait([_loadPanelSummary(), loadIssues(reset: true)]);
  }

  Future<void> setCurrentOfficeOnly(bool value) async {
    if (value == state.currentOfficeOnly) return;
    state = state.copyWith(
      currentOfficeOnly: value,
      selectedIds: const <int>{},
    );
    if (value && state.search.isEmpty) {
      state = state.copyWith(panelSummary: state.badgeSummary);
      await loadIssues(reset: true);
      return;
    }
    await Future.wait([_loadPanelSummary(), loadIssues(reset: true)]);
  }

  Future<void> _loadPanelSummary() async {
    try {
      final summary = await repository.getSummary(
        idPuntoVenta: state.currentOfficeOnly ? officeId : null,
        search: state.search,
      );
      if (!mounted) return;
      state = state.copyWith(panelSummary: summary);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(panelSummary: const InventorySyncSummary());
    }
  }

  Future<void> loadIssues({required bool reset}) async {
    if (!reset && (state.isLoadingIssues || state.last)) return;
    final requestVersion = reset ? ++_listRequestVersion : _listRequestVersion;
    final nextPage = reset ? 0 : state.pageNumber + 1;
    state = state.copyWith(
      isLoadingIssues: true,
      pageNumber: nextPage,
      issues: reset ? const [] : state.issues,
      last: reset ? false : state.last,
      clearError: true,
    );
    try {
      final page = await repository.getIssues(
        idPuntoVenta: state.currentOfficeOnly ? officeId : null,
        search: state.search,
        pageNumber: nextPage,
        perPage: state.perPage,
      );
      if (!mounted || requestVersion != _listRequestVersion) return;
      state = state.copyWith(
        issues: reset ? page.content : [...state.issues, ...page.content],
        totalRecords: page.totalElements,
        pageNumber: page.number,
        last: page.last,
        isLoadingIssues: false,
      );
    } catch (error) {
      if (!mounted || requestVersion != _listRequestVersion) return;
      state = state.copyWith(
        isLoadingIssues: false,
        pageNumber: reset ? 0 : state.pageNumber - 1,
        errorMessage: _message(error),
      );
    }
  }

  void toggleSelection(int inventoryId) {
    final selected = <int>{...state.selectedIds};
    if (!selected.add(inventoryId)) selected.remove(inventoryId);
    state = state.copyWith(selectedIds: selected);
  }

  void clearSelection() {
    state = state.copyWith(selectedIds: const <int>{});
  }

  Future<InventorySyncFixBatch> prepareFixBatch() async {
    if (state.selectedIds.isNotEmpty) {
      final ids = state.selectedIds.take(inventorySyncMaxBatch).toList();
      final selectedIssues = state.issues
          .where((issue) => ids.contains(issue.idInventory))
          .toList();
      return InventorySyncFixBatch(
        ids: ids,
        zeroStockWarnings: selectedIssues
            .where((issue) => issue.quedariaEnCero)
            .length,
        hasMore: state.selectedIds.length > inventorySyncMaxBatch,
        requestedTotal: state.selectedIds.length,
      );
    }

    final requestedTotal = state.totalRecords;
    if (requestedTotal == 0) return const InventorySyncFixBatch(ids: []);
    final page = await repository.getIssues(
      idPuntoVenta: state.currentOfficeOnly ? officeId : null,
      search: state.search,
      pageNumber: 0,
      perPage: requestedTotal.clamp(1, inventorySyncMaxBatch),
    );
    return InventorySyncFixBatch(
      ids: page.content.map((issue) => issue.idInventory).toList(),
      zeroStockWarnings: page.content
          .where((issue) => issue.quedariaEnCero)
          .length,
      hasMore: requestedTotal > inventorySyncMaxBatch,
      requestedTotal: requestedTotal,
    );
  }

  Future<InventorySyncFixResult> fixBatch(List<int> ids) async {
    state = state.copyWith(isFixing: true, clearError: true);
    try {
      final result = await repository.fixIssues(ids);
      if (!mounted) return result;
      state = state.copyWith(isFixing: false, selectedIds: const <int>{});
      await refreshAfterCorrection();
      return result;
    } catch (error) {
      if (mounted) {
        state = state.copyWith(isFixing: false, errorMessage: _message(error));
      }
      rethrow;
    }
  }

  Future<void> refreshAfterCorrection() async {
    _badgeRequest = _loadBadge(force: true);
    await _badgeRequest;
    if (!mounted) return;
    if (!(state.currentOfficeOnly && state.search.isEmpty)) {
      await _loadPanelSummary();
    }
    await loadIssues(reset: true);
  }

  String _message(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
}

class InventorySyncState {
  final InventorySyncSummary badgeSummary;
  final InventorySyncSummary panelSummary;
  final bool badgeLoaded;
  final bool isLoadingBadge;
  final List<InventorySyncIssue> issues;
  final Set<int> selectedIds;
  final int totalRecords;
  final int pageNumber;
  final int perPage;
  final bool last;
  final bool isLoadingIssues;
  final bool isFixing;
  final bool currentOfficeOnly;
  final String search;
  final String? errorMessage;

  const InventorySyncState({
    this.badgeSummary = const InventorySyncSummary(),
    this.panelSummary = const InventorySyncSummary(),
    this.badgeLoaded = false,
    this.isLoadingBadge = false,
    this.issues = const [],
    this.selectedIds = const <int>{},
    this.totalRecords = 0,
    this.pageNumber = 0,
    this.perPage = 20,
    this.last = false,
    this.isLoadingIssues = false,
    this.isFixing = false,
    this.currentOfficeOnly = true,
    this.search = '',
    this.errorMessage,
  });

  InventorySyncState copyWith({
    InventorySyncSummary? badgeSummary,
    InventorySyncSummary? panelSummary,
    bool? badgeLoaded,
    bool? isLoadingBadge,
    List<InventorySyncIssue>? issues,
    Set<int>? selectedIds,
    int? totalRecords,
    int? pageNumber,
    int? perPage,
    bool? last,
    bool? isLoadingIssues,
    bool? isFixing,
    bool? currentOfficeOnly,
    String? search,
    String? errorMessage,
    bool clearError = false,
  }) => InventorySyncState(
    badgeSummary: badgeSummary ?? this.badgeSummary,
    panelSummary: panelSummary ?? this.panelSummary,
    badgeLoaded: badgeLoaded ?? this.badgeLoaded,
    isLoadingBadge: isLoadingBadge ?? this.isLoadingBadge,
    issues: issues ?? this.issues,
    selectedIds: selectedIds ?? this.selectedIds,
    totalRecords: totalRecords ?? this.totalRecords,
    pageNumber: pageNumber ?? this.pageNumber,
    perPage: perPage ?? this.perPage,
    last: last ?? this.last,
    isLoadingIssues: isLoadingIssues ?? this.isLoadingIssues,
    isFixing: isFixing ?? this.isFixing,
    currentOfficeOnly: currentOfficeOnly ?? this.currentOfficeOnly,
    search: search ?? this.search,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}

class InventorySyncFixBatch {
  final List<int> ids;
  final int zeroStockWarnings;
  final bool hasMore;
  final int requestedTotal;

  const InventorySyncFixBatch({
    required this.ids,
    this.zeroStockWarnings = 0,
    this.hasMore = false,
    this.requestedTotal = 0,
  });
}
