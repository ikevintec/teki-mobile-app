import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail.dart';
import 'package:teki_app/src/data/repositories/restaurant_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/restaurant_repository.dart';
import 'package:teki_app/src/providers/kitchen/kitchen_state.dart';
import 'package:teki_app/src/providers/kitchen/kitchen_utils.dart';
import 'package:teki_app/src/shared/services/key_value_storage.dart';
import 'package:teki_app/src/shared/services/key_values_storage_impl.dart';
import 'package:teki_app/src/shared/services/socket_service.dart';

const _filtersStorageKey = 'kitchen_filters';
const _retentionDuration = Duration(milliseconds: 1500);
const _undoDuration = Duration(seconds: 10);
const _highlightDuration = Duration(seconds: 12);
const _cancellationNoticeDuration = Duration(minutes: 10);

final kitchenProvider =
    StateNotifierProvider.autoDispose<KitchenNotifier, KitchenState>((ref) {
      return KitchenNotifier(
        repository: RestaurantRepositoryImpl(),
        socketService: SocketService(),
        storage: KeyValueStorageServiceImpl(),
      );
    });

class KitchenNotifier extends StateNotifier<KitchenState> {
  final RestaurantRepository repository;
  final SocketService socketService;
  final KeyValueStorageService storage;

  KitchenNotifier({
    required this.repository,
    required this.socketService,
    required this.storage,
  }) : super(KitchenState.initial());

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _clockTimer;
  Timer? _refreshTimer;
  Timer? _socketDebounce;
  Timer? _undoTimer;
  final Map<int, Timer> _retentionTimers = {};
  StreamSubscription<dynamic>? _commandSubscription;
  StreamSubscription<dynamic>? _orderSubscription;
  final Map<int, String> _knownItemStatuses = {};
  final Set<int> _knownCommandIds = {};
  final Set<int> _lateNotifiedCommandIds = {};
  final Map<String, DateTime> _recentEvents = {};
  bool _initialized = false;
  bool _socketRequested = false;
  bool _initialLoadDone = false;
  bool _highlightNewCommandsAfterLoad = false;
  int _requestVersion = 0;

  Future<void> initialize({
    required int officeId,
    required String officeCode,
  }) async {
    if (_initialized && state.officeId == officeId) return;
    _initialized = true;
    await _restoreFilters();
    if (!mounted) return;
    state = state.copyWith(officeId: officeId, isLoading: true);
    _startTimers();
    _listenToSocket();
    _socketRequested = true;
    unawaited(socketService.connect(officeCode: officeCode));
    await Future.wait([loadProductionAreas(), refresh()]);
  }

  Future<void> loadProductionAreas() async {
    try {
      final areas = await repository.getProductionAreas();
      if (!mounted) return;
      state = state.copyWith(productionAreas: areas);
    } catch (_) {
      // Cocina puede operar sin el filtro de zonas si esta consulta falla.
    }
  }

  Future<void> refresh({bool silent = false}) async {
    final officeId = state.officeId;
    if (officeId == null || officeId <= 0) return;
    final request = ++_requestVersion;
    state = state.copyWith(
      isLoading: !silent && state.commands.isEmpty,
      isRefreshing: true,
      clearError: true,
    );
    try {
      final commands = await repository.getCommands(_buildQuery(officeId));
      if (!mounted || request != _requestVersion) return;
      commands.sort((a, b) {
        final aDate = a.fecha ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.fecha ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aDate.compareTo(bDate);
      });
      _processLoadedCommands(commands);
    } catch (error) {
      if (!mounted || request != _requestVersion) return;
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: _messageFrom(error),
      );
    }
  }

  Map<String, dynamic> _buildQuery(int officeId) {
    final now = DateTime.now();
    final format = DateFormat('dd-MM-yyyy');
    return {
      'desde': format.format(now.subtract(const Duration(days: 1))),
      'hasta': format.format(now),
      'estadoPedido': const [
        'PENDIENTE',
        'PREPARADO',
        'PRECUENTA',
        'CANCELADO',
      ],
      'idPuntoVenta': officeId,
      if (state.filters.productionAreaIds.isNotEmpty)
        'idAreaProduccion': state.filters.productionAreaIds,
    };
  }

  void _processLoadedCommands(List<Command> commands) {
    final now = DateTime.now();
    final cancellationNotices = Map<int, KitchenCancellationNotice>.from(
      state.cancellationNotices,
    );
    final currentStatuses = <int, String>{};
    for (final command in commands) {
      for (final item in command.items ?? const <CommandDetail>[]) {
        final itemId = item.id;
        final status = item.estadoComandaDetalle;
        if (itemId == null || status == null || item.eliminado == true) {
          continue;
        }
        final previousStatus = _knownItemStatuses[itemId];
        if (previousStatus != null &&
            previousStatus != 'CANCELADO' &&
            status == 'CANCELADO') {
          final previousView = kitchenViewForStatus(previousStatus);
          if (previousView != null) {
            cancellationNotices[itemId] = KitchenCancellationNotice(
              itemId: itemId,
              commandId: command.id ?? 0,
              previousView: previousView,
              createdAt: now,
            );
          }
        }
        currentStatuses[itemId] = status;
      }
    }
    _knownItemStatuses
      ..clear()
      ..addAll(currentStatuses);

    final highlights = Map<int, KitchenHighlight>.from(state.highlights);
    final currentIds = commands
        .map((command) => command.id)
        .whereType<int>()
        .toSet();
    if (_highlightNewCommandsAfterLoad && _initialLoadDone) {
      for (final id in currentIds.difference(_knownCommandIds)) {
        highlights[id] = KitchenHighlight(
          type: KitchenHighlightType.newOrder,
          expiresAt: now.add(_highlightDuration),
        );
      }
    }
    _highlightNewCommandsAfterLoad = false;
    _knownCommandIds
      ..clear()
      ..addAll(currentIds);

    final pending = Map<int, String>.from(state.pendingStatuses);
    for (final entry in currentStatuses.entries) {
      if (pending[entry.key] == entry.value) pending.remove(entry.key);
    }

    state = state.copyWith(
      commands: commands,
      isLoading: false,
      isRefreshing: false,
      lastUpdated: now,
      pendingStatuses: pending,
      cancellationNotices: cancellationNotices,
      highlights: highlights,
      clearError: true,
    );

    if (!_initialLoadDone) {
      _initialLoadDone = true;
      for (final command in _lateCommands()) {
        if (command.id != null) _lateNotifiedCommandIds.add(command.id!);
      }
    }
  }

  Future<void> advanceItem(Command command, CommandDetail item) async {
    final commandId = command.id;
    final itemId = item.id;
    final currentStatus = item.estadoComandaDetalle;
    final nextStatus = kitchenNextStatus[currentStatus];
    if (commandId == null ||
        itemId == null ||
        nextStatus == null ||
        state.busyItemIds.contains(itemId)) {
      return;
    }
    _beginOptimistic(
      itemIds: [itemId],
      newStatus: nextStatus,
      originalView: state.filters.view,
    );
    try {
      await repository.updateCommandItemStatus(commandId, itemId, nextStatus);
      if (!mounted) return;
      _completeChange(
        commandId: commandId,
        itemIds: [itemId],
        itemName: item.producto?.nombre ?? 'Plato',
        newStatus: nextStatus,
      );
      unawaited(refresh(silent: true));
    } catch (error) {
      _revertOptimistic([itemId], error);
    }
  }

  Future<void> advanceAll(Command command) async {
    final commandId = command.id;
    final view = state.filters.view;
    final target = switch (view) {
      KitchenView.pending => 'PREPARADO',
      KitchenView.ready => 'DESPACHADO',
      _ => null,
    };
    if (commandId == null || target == null) return;
    final itemIds = kitchenItemsForView(command, state)
        .where(
          (item) =>
              item.id != null &&
              kitchenNextStatus.containsKey(item.estadoComandaDetalle) &&
              !state.busyItemIds.contains(item.id),
        )
        .map((item) => item.id!)
        .toList();
    if (itemIds.length < 2) return;
    _beginOptimistic(itemIds: itemIds, newStatus: target, originalView: view);
    try {
      await repository.updateCommandItemsStatus(commandId, itemIds, target);
      if (!mounted) return;
      _completeChange(
        commandId: commandId,
        itemIds: itemIds,
        itemName: kitchenCommandTitle(command),
        newStatus: target,
      );
      unawaited(refresh(silent: true));
    } catch (error) {
      _revertOptimistic(itemIds, error);
    }
  }

  void _beginOptimistic({
    required List<int> itemIds,
    required String newStatus,
    required KitchenView originalView,
  }) {
    final pending = Map<int, String>.from(state.pendingStatuses);
    final busy = Set<int>.from(state.busyItemIds);
    final retained = Map<int, KitchenView>.from(state.retainedViews);
    for (final itemId in itemIds) {
      pending[itemId] = newStatus;
      busy.add(itemId);
      retained[itemId] = originalView;
      _retentionTimers[itemId]?.cancel();
      _retentionTimers[itemId] = Timer(_retentionDuration, () {
        if (!mounted) return;
        final nextRetained = Map<int, KitchenView>.from(state.retainedViews)
          ..remove(itemId);
        state = state.copyWith(retainedViews: nextRetained);
      });
    }
    state = state.copyWith(
      pendingStatuses: pending,
      busyItemIds: busy,
      retainedViews: retained,
      clearError: true,
    );
  }

  void _completeChange({
    required int commandId,
    required List<int> itemIds,
    required String itemName,
    required String newStatus,
  }) {
    final busy = Set<int>.from(state.busyItemIds)..removeAll(itemIds);
    final undo = KitchenUndoAction(
      commandId: commandId,
      itemIds: itemIds,
      itemName: itemName,
      newStatus: newStatus,
      expiresAt: DateTime.now().add(_undoDuration),
    );
    state = state.copyWith(busyItemIds: busy, undoAction: undo);
    _undoTimer?.cancel();
    _undoTimer = Timer(_undoDuration, () {
      if (mounted) state = state.copyWith(clearUndo: true);
    });
  }

  void _revertOptimistic(List<int> itemIds, Object error) {
    if (!mounted) return;
    final pending = Map<int, String>.from(state.pendingStatuses)
      ..removeWhere((key, _) => itemIds.contains(key));
    final busy = Set<int>.from(state.busyItemIds)..removeAll(itemIds);
    final retained = Map<int, KitchenView>.from(state.retainedViews)
      ..removeWhere((key, _) => itemIds.contains(key));
    for (final itemId in itemIds) {
      _retentionTimers.remove(itemId)?.cancel();
    }
    state = state.copyWith(
      pendingStatuses: pending,
      busyItemIds: busy,
      retainedViews: retained,
      errorMessage: _messageFrom(error),
    );
  }

  Future<void> undoLastChange() async {
    final undo = state.undoAction;
    if (undo == null || undo.expiresAt.isBefore(DateTime.now())) return;
    final previousStatus = kitchenPreviousStatus[undo.newStatus];
    if (previousStatus == null) return;
    state = state.copyWith(clearUndo: true);
    _undoTimer?.cancel();
    try {
      if (undo.itemIds.length == 1) {
        await repository.updateCommandItemStatus(
          undo.commandId,
          undo.itemIds.first,
          previousStatus,
        );
      } else {
        await repository.updateCommandItemsStatus(
          undo.commandId,
          undo.itemIds,
          previousStatus,
        );
      }
      await refresh(silent: true);
    } catch (error) {
      if (mounted) state = state.copyWith(errorMessage: _messageFrom(error));
    }
  }

  void setView(KitchenView view) =>
      _setFilters(state.filters.copyWith(view: view));

  void setMode(KitchenOrderMode mode) =>
      _setFilters(state.filters.copyWith(mode: mode));

  Future<void> setProductionAreas(List<int> ids) async {
    _setFilters(state.filters.copyWith(productionAreaIds: ids));
    await refresh(silent: true);
  }

  void setPreparationMinutes(int value) => _setFilters(
    state.filters.copyWith(preparationMinutes: value.clamp(1, 240).toInt()),
  );

  void setSoundEnabled(bool value) =>
      _setFilters(state.filters.copyWith(soundEnabled: value));

  void setAlertTone(KitchenAlertTone value) =>
      _setFilters(state.filters.copyWith(alertTone: value));

  void setLateAlertEnabled(bool value) =>
      _setFilters(state.filters.copyWith(lateAlertEnabled: value));

  void setShowCancelled(bool value) =>
      _setFilters(state.filters.copyWith(showCancelled: value));

  void clearVisibleFilters() {
    _setFilters(
      state.filters.copyWith(
        mode: KitchenOrderMode.all,
        productionAreaIds: const [],
      ),
    );
    unawaited(refresh(silent: true));
  }

  void markCancellationsSeen(int commandId) {
    final notices = Map<int, KitchenCancellationNotice>.from(
      state.cancellationNotices,
    )..removeWhere((_, notice) => notice.commandId == commandId);
    state = state.copyWith(cancellationNotices: notices);
  }

  void clearError() => state = state.copyWith(clearError: true);

  void _setFilters(KitchenFilters filters) {
    state = state.copyWith(filters: filters);
    unawaited(
      storage.setKeyValue<String>(
        _filtersStorageKey,
        jsonEncode(filters.toJson()),
      ),
    );
  }

  Future<void> _restoreFilters() async {
    try {
      final stored = await storage.getValue<String>(_filtersStorageKey);
      if (stored == null || stored.isEmpty || !mounted) return;
      final decoded = jsonDecode(stored);
      if (decoded is Map<String, dynamic>) {
        state = state.copyWith(filters: KitchenFilters.fromJson(decoded));
      }
    } catch (_) {
      // Preferencias corruptas o almacenamiento no disponible: usar defaults.
    }
  }

  void _startTimers() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final now = DateTime.now();
      _cleanupTransientState(now);
      state = state.copyWith(
        now: now,
        socketConnected: socketService.isConnected,
      );
      _checkLateCommands();
    });
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(refresh(silent: true)),
    );
  }

  void _cleanupTransientState(DateTime now) {
    final highlights = Map<int, KitchenHighlight>.from(state.highlights)
      ..removeWhere((_, value) => value.expiresAt.isBefore(now));
    final notices =
        Map<int, KitchenCancellationNotice>.from(state.cancellationNotices)
          ..removeWhere(
            (_, value) =>
                now.difference(value.createdAt) > _cancellationNoticeDuration,
          );
    if (highlights.length != state.highlights.length ||
        notices.length != state.cancellationNotices.length) {
      state = state.copyWith(
        highlights: highlights,
        cancellationNotices: notices,
      );
    }
  }

  List<Command> _lateCommands() {
    return kitchenCommandsForView(state, view: KitchenView.pending)
        .where(
          (command) =>
              kitchenTimeBand(
                command,
                state.filters.preparationMinutes,
                DateTime.now(),
              ) ==
              'late',
        )
        .toList();
  }

  void _checkLateCommands() {
    if (!_initialLoadDone) return;
    final newLate = _lateCommands().where(
      (command) =>
          command.id != null && !_lateNotifiedCommandIds.contains(command.id),
    );
    var found = false;
    for (final command in newLate) {
      _lateNotifiedCommandIds.add(command.id!);
      found = true;
    }
    if (found && state.filters.lateAlertEnabled) _playSecondaryAlert();
  }

  void _listenToSocket() {
    _commandSubscription?.cancel();
    _orderSubscription?.cancel();
    _commandSubscription = socketService
        .on(SocketEvent.commandRestaurant)
        .listen((event) => _handleSocketEvent(event, isOrderChannel: false));
    _orderSubscription = socketService
        .on(SocketEvent.orderRestaurant)
        .listen((event) => _handleSocketEvent(event, isOrderChannel: true));
  }

  void _handleSocketEvent(dynamic raw, {required bool isOrderChannel}) {
    final event = _normalizeEvent(raw, isOrderChannel: isOrderChannel);
    if (event == null || _isDuplicateEvent(event)) return;
    final eventOffice = (event['idPuntoVenta'] as num?)?.toInt();
    if (eventOffice != null &&
        state.officeId != null &&
        eventOffice != state.officeId) {
      return;
    }
    final type = event['tipo']?.toString() ?? 'LEGACY';
    final touchesAreas = _eventTouchesSelectedAreas(event);
    switch (type) {
      case 'COMANDA_NUEVA':
        if (touchesAreas) {
          _highlightNewCommandsAfterLoad = true;
          final commandId = (event['idComanda'] as num?)?.toInt();
          if (commandId != null) {
            _highlight(commandId, KitchenHighlightType.newOrder);
          }
          _playPrimaryAlert();
        }
        _scheduleSocketRefresh();
      case 'PLATO_ANULADO':
        final commandId = (event['idComanda'] as num?)?.toInt();
        if (commandId != null) {
          _highlight(commandId, KitchenHighlightType.cancelled);
        }
        if (touchesAreas) {
          _playSecondaryAlert();
        }
        _scheduleSocketRefresh();
      case 'PEDIDO_ESTADO':
        final status = event['estado']?.toString();
        if (status == 'CANCELADO' || status == 'RECHAZADO') {
          final orderId = (event['idPedido'] as num?)?.toInt();
          for (final command in state.commands) {
            if (command.pedido?.id == orderId && command.id != null) {
              _highlight(command.id!, KitchenHighlightType.cancelled);
            }
          }
          _playSecondaryAlert();
        }
        _scheduleSocketRefresh();
      case 'LEGACY':
        _highlightNewCommandsAfterLoad = true;
        _playPrimaryAlert();
        _scheduleSocketRefresh();
      default:
        _scheduleSocketRefresh();
    }
  }

  Map<String, dynamic>? _normalizeEvent(
    dynamic raw, {
    required bool isOrderChannel,
  }) {
    dynamic value = raw;
    if (raw is Map && raw.containsKey('value')) value = raw['value'];
    if (value == null) return null;
    if (value is! Map) {
      return {
        'tipo': isOrderChannel ? 'PEDIDO_ONLINE_NUEVO' : 'LEGACY',
        'idEmpresa': value,
      };
    }
    final event = Map<String, dynamic>.from(value);
    event['tipo'] ??= isOrderChannel ? 'PEDIDO_ONLINE_NUEVO' : 'LEGACY';
    return event;
  }

  bool _isDuplicateEvent(Map<String, dynamic> event) {
    final timestamp = event['ts'];
    if (timestamp == null) return false;
    final now = DateTime.now();
    _recentEvents.removeWhere(
      (_, seenAt) => now.difference(seenAt) > const Duration(seconds: 3),
    );
    final key = [
      event['tipo'],
      event['idPedido'],
      event['idComanda'],
      timestamp,
    ].join('|');
    if (_recentEvents.containsKey(key)) return true;
    _recentEvents[key] = now;
    return false;
  }

  bool _eventTouchesSelectedAreas(Map<String, dynamic> event) {
    final selected = state.filters.productionAreaIds;
    final eventAreas = (event['zonas'] as List? ?? const [])
        .whereType<num>()
        .map((value) => value.toInt())
        .toList();
    return selected.isEmpty ||
        eventAreas.isEmpty ||
        eventAreas.any(selected.contains);
  }

  void _highlight(int commandId, KitchenHighlightType type) {
    final highlights = Map<int, KitchenHighlight>.from(state.highlights);
    final current = highlights[commandId];
    if (current?.type == KitchenHighlightType.cancelled &&
        type == KitchenHighlightType.newOrder) {
      return;
    }
    highlights[commandId] = KitchenHighlight(
      type: type,
      expiresAt: DateTime.now().add(_highlightDuration),
    );
    state = state.copyWith(highlights: highlights);
  }

  void _scheduleSocketRefresh() {
    _socketDebounce?.cancel();
    _socketDebounce = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(refresh(silent: true)),
    );
  }

  void _playPrimaryAlert() {
    if (!state.filters.soundEnabled) return;
    final file = switch (state.filters.alertTone) {
      KitchenAlertTone.classic => 'swiftly.mp3',
      KitchenAlertTone.bell => 'new_order_bell.wav',
      KitchenAlertTone.soft => 'new_order_soft.wav',
    };
    unawaited(_playAsset(file));
    unawaited(
      state.filters.alertTone == KitchenAlertTone.soft
          ? HapticFeedback.lightImpact()
          : HapticFeedback.mediumImpact(),
    );
  }

  void _playSecondaryAlert() {
    if (!state.filters.soundEnabled) return;
    unawaited(_playAsset('new_order_soft.wav', volume: 0.6));
    unawaited(HapticFeedback.lightImpact());
  }

  /// Reproduce un chime desde assets. Usa un reproductor real (audioplayers)
  /// porque `SystemSound` no emite audio en Android y va al stream de UI.
  Future<void> _playAsset(String file, {double volume = 1.0}) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/$file'), volume: volume);
    } catch (_) {
      // Si el audio falla (formato/permiso), la cocina sigue operando.
    }
  }

  String _messageFrom(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _refreshTimer?.cancel();
    _socketDebounce?.cancel();
    _undoTimer?.cancel();
    for (final timer in _retentionTimers.values) {
      timer.cancel();
    }
    _commandSubscription?.cancel();
    _orderSubscription?.cancel();
    unawaited(_audioPlayer.dispose());
    if (_socketRequested) socketService.disconnect();
    super.dispose();
  }
}
