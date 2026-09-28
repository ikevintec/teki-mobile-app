import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/config.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/restaurant_event.dart';
import 'package:teki_app/src/data/repositories/restaurant_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/restaurant_repository.dart';
import 'package:teki_app/src/shared/services/command_print_service.dart';
import 'package:teki_app/src/shared/services/restaurant_events_service.dart';
import 'package:teki_app/src/utils/notifications.dart';

const _notProvided = Object();

final qrCommandReviewProvider =
    StateNotifierProvider.autoDispose<
      QrCommandReviewNotifier,
      QrCommandReviewState
    >((ref) {
      return QrCommandReviewNotifier(
        repository: RestaurantRepositoryImpl(),
        eventsService: RestaurantEventsService(),
        printService: CommandPrintService(),
      );
    });

class QrCommandReviewNotifier extends StateNotifier<QrCommandReviewState> {
  final RestaurantRepository repository;
  final RestaurantEventsService eventsService;
  final CommandPrintService printService;

  final Set<int> _seenCommandIds = {};
  Office? _office;
  ConfigCompany? _config;
  int? _companyId;
  int _requestVersion = 0;

  QrCommandReviewNotifier({
    required this.repository,
    required this.eventsService,
    required this.printService,
  }) : super(const QrCommandReviewState()) {
    eventsService.listen(_handleRestaurantEvent);
  }

  Future<void> initialize({
    required Office office,
    ConfigCompany? config,
    int? companyId,
  }) async {
    final officeId = office.id;
    if (officeId == null) return;

    final changedOffice = _office?.id != officeId;
    _office = office;
    _config = config;
    _companyId = companyId;
    if (!changedOffice && state.officeId == officeId) return;

    _seenCommandIds.clear();
    state = QrCommandReviewState(
      officeId: officeId,
      isLoading: true,
      autoOpenRequest: state.autoOpenRequest,
      tablesRefreshRequest: state.tablesRefreshRequest,
    );
    await refresh();
  }

  Future<void> refresh({bool revealNewCommands = true}) async {
    final officeId = _office?.id;
    if (officeId == null) return;
    final request = ++_requestVersion;
    state = state.copyWith(
      isLoading: state.pendingCommands.isEmpty,
      isRefreshing: true,
      errorMessage: null,
    );

    try {
      final commands = await repository.getPendingQrCommands(officeId);
      if (!mounted || request != _requestVersion || _office?.id != officeId) {
        return;
      }
      commands.sort((a, b) {
        final aDate = a.fecha ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.fecha ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aDate.compareTo(bDate);
      });
      final hasNewCommands = commands.any(
        (command) =>
            command.id != null && !_seenCommandIds.contains(command.id),
      );
      _seenCommandIds.addAll(
        commands.map((command) => command.id).whereType<int>(),
      );
      state = state.copyWith(
        pendingCommands: commands,
        isLoading: false,
        isRefreshing: false,
        autoOpenRequest: revealNewCommands && hasNewCommands
            ? state.autoOpenRequest + 1
            : state.autoOpenRequest,
      );
    } catch (error) {
      if (!mounted || request != _requestVersion) return;
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: _messageFrom(error),
      );
    }
  }

  Future<bool> approve(Command command, {bool attend = false}) =>
      _review(command, status: 'APROBADA', attend: attend);

  Future<bool> reject(Command command) => _review(command, status: 'RECHAZADA');

  Future<bool> _review(
    Command command, {
    required String status,
    bool attend = false,
  }) async {
    final commandId = command.id;
    if (commandId == null || state.processingCommandId != null) return false;

    state = state.copyWith(processingCommandId: commandId, errorMessage: null);
    try {
      await repository.reviewQrCommands([commandId], status, attend: attend);
      if (!mounted) return false;

      var printFailed = false;
      if (status == 'APROBADA' && _office != null) {
        try {
          await printService.processCommand(
            commandId: commandId,
            puntoVenta: _office!,
            escPos: _config?.imprimeTicketsEscPos ?? false,
            clientPrinter: _config?.clienteImpresion,
            idCompany: _companyId,
          );
        } catch (_) {
          printFailed = true;
        }
      }
      if (!mounted) return false;

      final commandNumber = command.numeroComanda ?? commandId;
      final approved = status == 'APROBADA';
      state = state.copyWith(
        pendingCommands: state.pendingCommands
            .where((item) => item.id != commandId)
            .toList(growable: false),
        processingCommandId: null,
        tablesRefreshRequest: state.tablesRefreshRequest + 1,
      );
      if (printFailed) {
        warningNotification(
          'Comanda #$commandNumber aprobada, pero no se pudo imprimir. '
          'Puedes reimprimirla desde el detalle.',
          duration: const Duration(seconds: 4),
        );
      } else {
        successNotification(
          approved
              ? 'Comanda #$commandNumber aprobada y enviada a cocina${attend ? '. Ahora atiendes la mesa' : ''}'
              : 'Comanda #$commandNumber rechazada',
        );
      }
      return true;
    } catch (error) {
      if (!mounted) return false;
      final message = _messageFrom(error);
      state = state.copyWith(processingCommandId: null, errorMessage: message);
      errorNotification(message);
      unawaited(refresh(revealNewCommands: false));
      return false;
    }
  }

  void _handleRestaurantEvent(RestaurantEvent event) {
    if (!event.belongsToOffice(_office?.id)) return;
    switch (event.type) {
      case RestaurantEventType.qrPendingApproval:
        unawaited(refresh());
      case RestaurantEventType.qrReviewed:
        state = state.copyWith(
          tablesRefreshRequest: state.tablesRefreshRequest + 1,
        );
        unawaited(refresh(revealNewCommands: false));
    }
  }

  String _messageFrom(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  @override
  void dispose() {
    unawaited(eventsService.dispose());
    super.dispose();
  }
}

class QrCommandReviewState {
  final int? officeId;
  final List<Command> pendingCommands;
  final bool isLoading;
  final bool isRefreshing;
  final int? processingCommandId;
  final String? errorMessage;
  final int autoOpenRequest;
  final int tablesRefreshRequest;

  const QrCommandReviewState({
    this.officeId,
    this.pendingCommands = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.processingCommandId,
    this.errorMessage,
    this.autoOpenRequest = 0,
    this.tablesRefreshRequest = 0,
  });

  QrCommandReviewState copyWith({
    int? officeId,
    List<Command>? pendingCommands,
    bool? isLoading,
    bool? isRefreshing,
    Object? processingCommandId = _notProvided,
    Object? errorMessage = _notProvided,
    int? autoOpenRequest,
    int? tablesRefreshRequest,
  }) {
    return QrCommandReviewState(
      officeId: officeId ?? this.officeId,
      pendingCommands: pendingCommands ?? this.pendingCommands,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      processingCommandId: identical(processingCommandId, _notProvided)
          ? this.processingCommandId
          : processingCommandId as int?,
      errorMessage: identical(errorMessage, _notProvided)
          ? this.errorMessage
          : errorMessage as String?,
      autoOpenRequest: autoOpenRequest ?? this.autoOpenRequest,
      tablesRefreshRequest: tablesRefreshRequest ?? this.tablesRefreshRequest,
    );
  }
}
