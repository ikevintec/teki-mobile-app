import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/replicador/replicador_app.dart';
import 'package:teki_app/src/data/repositories/replicador_app_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/replicador_app_repository.dart';

class ReplicadorAppState {
  final List<ReplicadorApp> apps;
  final bool loading;
  final bool updating;
  final String? error;

  const ReplicadorAppState({
    this.apps = const [],
    this.loading = false,
    this.updating = false,
    this.error,
  });

  Set<NotificationAppType> get selectedTypes =>
      apps.where((app) => app.selected).map((app) => app.type).toSet();

  ReplicadorAppState copyWith({
    List<ReplicadorApp>? apps,
    bool? loading,
    bool? updating,
    String? error,
    bool clearError = false,
  }) => ReplicadorAppState(
    apps: apps ?? this.apps,
    loading: loading ?? this.loading,
    updating: updating ?? this.updating,
    error: clearError ? null : error ?? this.error,
  );
}

class ReplicadorAppNotifier extends StateNotifier<ReplicadorAppState> {
  final ReplicadorAppRepository repository;

  ReplicadorAppNotifier(this.repository) : super(const ReplicadorAppState());

  Future<void> initialize({required bool enabled}) async {
    if (!enabled) {
      clear();
      return;
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      state = ReplicadorAppState(apps: await repository.getApps());
    } catch (e) {
      state = ReplicadorAppState(error: e.toString());
    }
  }

  Future<void> updateSelection(Set<NotificationAppType> types) async {
    state = state.copyWith(updating: true, clearError: true);
    try {
      state = ReplicadorAppState(apps: await repository.updateApps(types));
    } catch (e) {
      state = state.copyWith(updating: false, error: e.toString());
      rethrow;
    }
  }

  void clear() => state = const ReplicadorAppState();
}

final replicadorAppProvider =
    StateNotifierProvider<ReplicadorAppNotifier, ReplicadorAppState>((ref) {
      return ReplicadorAppNotifier(ReplicadorAppRepositoryImpl());
    });
