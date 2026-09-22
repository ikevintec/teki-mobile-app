import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/production_area.dart';

enum KitchenView { pending, ready, served, cancelled }

extension KitchenViewX on KitchenView {
  String get label => switch (this) {
    KitchenView.pending => 'Pendientes',
    KitchenView.ready => 'Listos',
    KitchenView.served => 'Servidos',
    KitchenView.cancelled => 'Anulados',
  };

  List<String> get statuses => switch (this) {
    KitchenView.pending => const ['PENDIENTE', 'PREPARACION'],
    KitchenView.ready => const ['PREPARADO'],
    KitchenView.served => const ['DESPACHADO'],
    KitchenView.cancelled => const ['CANCELADO'],
  };
}

enum KitchenOrderMode { all, dineIn, takeaway }

extension KitchenOrderModeX on KitchenOrderMode {
  String get label => switch (this) {
    KitchenOrderMode.all => 'Todo',
    KitchenOrderMode.dineIn => 'Para aquí',
    KitchenOrderMode.takeaway => 'Llevar',
  };
}

enum KitchenAlertTone { classic, bell, soft }

extension KitchenAlertToneX on KitchenAlertTone {
  String get label => switch (this) {
    KitchenAlertTone.classic => 'Clásico',
    KitchenAlertTone.bell => 'Campana',
    KitchenAlertTone.soft => 'Suave',
  };
}

enum KitchenHighlightType { newOrder, cancelled }

class KitchenFilters {
  final KitchenView view;
  final KitchenOrderMode mode;
  final int preparationMinutes;
  final List<int> productionAreaIds;
  final bool soundEnabled;
  final KitchenAlertTone alertTone;
  final bool lateAlertEnabled;
  final bool showCancelled;

  const KitchenFilters({
    this.view = KitchenView.pending,
    this.mode = KitchenOrderMode.all,
    this.preparationMinutes = 15,
    this.productionAreaIds = const [],
    this.soundEnabled = true,
    this.alertTone = KitchenAlertTone.classic,
    this.lateAlertEnabled = true,
    this.showCancelled = false,
  });

  KitchenFilters copyWith({
    KitchenView? view,
    KitchenOrderMode? mode,
    int? preparationMinutes,
    List<int>? productionAreaIds,
    bool? soundEnabled,
    KitchenAlertTone? alertTone,
    bool? lateAlertEnabled,
    bool? showCancelled,
  }) {
    return KitchenFilters(
      view: view ?? this.view,
      mode: mode ?? this.mode,
      preparationMinutes: preparationMinutes ?? this.preparationMinutes,
      productionAreaIds: productionAreaIds ?? this.productionAreaIds,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      alertTone: alertTone ?? this.alertTone,
      lateAlertEnabled: lateAlertEnabled ?? this.lateAlertEnabled,
      showCancelled: showCancelled ?? this.showCancelled,
    );
  }

  factory KitchenFilters.fromJson(Map<String, dynamic> json) {
    KitchenView parseView() => KitchenView.values.firstWhere(
      (value) => value.name == json['view'],
      orElse: () => KitchenView.pending,
    );
    KitchenOrderMode parseMode() => KitchenOrderMode.values.firstWhere(
      (value) => value.name == json['mode'],
      orElse: () => KitchenOrderMode.all,
    );
    KitchenAlertTone parseTone() => KitchenAlertTone.values.firstWhere(
      (value) => value.name == json['alertTone'],
      orElse: () => KitchenAlertTone.classic,
    );

    return KitchenFilters(
      view: parseView(),
      mode: parseMode(),
      preparationMinutes:
          (json['preparationMinutes'] as num?)?.toInt().clamp(1, 240).toInt() ??
          15,
      productionAreaIds: (json['productionAreaIds'] as List? ?? const [])
          .whereType<num>()
          .map((value) => value.toInt())
          .toList(),
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      alertTone: parseTone(),
      lateAlertEnabled: json['lateAlertEnabled'] as bool? ?? true,
      showCancelled: json['showCancelled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'view': view.name,
    'mode': mode.name,
    'preparationMinutes': preparationMinutes,
    'productionAreaIds': productionAreaIds,
    'soundEnabled': soundEnabled,
    'alertTone': alertTone.name,
    'lateAlertEnabled': lateAlertEnabled,
    'showCancelled': showCancelled,
  };
}

class KitchenCancellationNotice {
  final int itemId;
  final int commandId;
  final KitchenView previousView;
  final DateTime createdAt;

  const KitchenCancellationNotice({
    required this.itemId,
    required this.commandId,
    required this.previousView,
    required this.createdAt,
  });
}

class KitchenHighlight {
  final KitchenHighlightType type;
  final DateTime expiresAt;

  const KitchenHighlight({required this.type, required this.expiresAt});
}

class KitchenUndoAction {
  final int commandId;
  final List<int> itemIds;
  final String itemName;
  final String newStatus;
  final DateTime expiresAt;

  const KitchenUndoAction({
    required this.commandId,
    required this.itemIds,
    required this.itemName,
    required this.newStatus,
    required this.expiresAt,
  });
}

class KitchenState {
  final int? officeId;
  final List<Command> commands;
  final List<ProductionArea> productionAreas;
  final KitchenFilters filters;
  final bool isLoading;
  final bool isRefreshing;
  final bool socketConnected;
  final DateTime now;
  final DateTime? lastUpdated;
  final String? errorMessage;
  final Map<int, String> pendingStatuses;
  final Set<int> busyItemIds;
  final Map<int, KitchenView> retainedViews;
  final Map<int, KitchenCancellationNotice> cancellationNotices;
  final Map<int, KitchenHighlight> highlights;
  final KitchenUndoAction? undoAction;

  const KitchenState({
    this.officeId,
    this.commands = const [],
    this.productionAreas = const [],
    this.filters = const KitchenFilters(),
    this.isLoading = true,
    this.isRefreshing = false,
    this.socketConnected = false,
    required this.now,
    this.lastUpdated,
    this.errorMessage,
    this.pendingStatuses = const {},
    this.busyItemIds = const {},
    this.retainedViews = const {},
    this.cancellationNotices = const {},
    this.highlights = const {},
    this.undoAction,
  });

  factory KitchenState.initial() => KitchenState(now: DateTime.now());

  KitchenState copyWith({
    int? officeId,
    List<Command>? commands,
    List<ProductionArea>? productionAreas,
    KitchenFilters? filters,
    bool? isLoading,
    bool? isRefreshing,
    bool? socketConnected,
    DateTime? now,
    DateTime? lastUpdated,
    String? errorMessage,
    bool clearError = false,
    Map<int, String>? pendingStatuses,
    Set<int>? busyItemIds,
    Map<int, KitchenView>? retainedViews,
    Map<int, KitchenCancellationNotice>? cancellationNotices,
    Map<int, KitchenHighlight>? highlights,
    KitchenUndoAction? undoAction,
    bool clearUndo = false,
  }) {
    return KitchenState(
      officeId: officeId ?? this.officeId,
      commands: commands ?? this.commands,
      productionAreas: productionAreas ?? this.productionAreas,
      filters: filters ?? this.filters,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      socketConnected: socketConnected ?? this.socketConnected,
      now: now ?? this.now,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pendingStatuses: pendingStatuses ?? this.pendingStatuses,
      busyItemIds: busyItemIds ?? this.busyItemIds,
      retainedViews: retainedViews ?? this.retainedViews,
      cancellationNotices: cancellationNotices ?? this.cancellationNotices,
      highlights: highlights ?? this.highlights,
      undoAction: clearUndo ? null : (undoAction ?? this.undoAction),
    );
  }
}
