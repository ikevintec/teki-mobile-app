import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/repositories/restaurant_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/restaurant_repository.dart';
import 'package:teki_app/src/utils/notifications.dart';

final readyToServeProvider =
    StateNotifierProvider<ReadyToServeNotifier, ReadyToServeState>((ref) {
      return ReadyToServeNotifier(repository: RestaurantRepositoryImpl());
    });

class ReadyDish {
  final int commandId;
  final int itemId;
  final String name;
  final double quantity;
  final String? note;
  final DateTime preparedAt;

  const ReadyDish({
    required this.commandId,
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.preparedAt,
    this.note,
  });
}

class ReadyTableGroup {
  final int orderId;
  final String title;
  final String subtitle;
  final List<ReadyDish> dishes;
  final DateTime waitingSince;

  const ReadyTableGroup({
    required this.orderId,
    required this.title,
    required this.subtitle,
    required this.dishes,
    required this.waitingSince,
  });
}

List<ReadyTableGroup> groupReadyCommands(
  List<Command> commands, {
  DateTime? fallbackDate,
}) {
  final fallback = fallbackDate ?? DateTime.now();
  final grouped = <int, List<ReadyDish>>{};
  final titles = <int, String>{};
  final subtitles = <int, String>{};

  for (final command in commands) {
    final order = command.pedido;
    final commandId = command.id;
    final orderId = order?.id;
    final table = order?.mesa;
    if (commandId == null ||
        orderId == null ||
        order?.tipo != 'LOCAL' ||
        table == null) {
      continue;
    }

    for (final item in command.items ?? const []) {
      if (item.id == null ||
          item.eliminado == true ||
          item.estadoComandaDetalle?.toUpperCase() != 'PREPARADO') {
        continue;
      }
      grouped
          .putIfAbsent(orderId, () => [])
          .add(
            ReadyDish(
              commandId: commandId,
              itemId: item.id!,
              name: item.producto?.nombre ?? '-',
              quantity: item.cantidad ?? 0,
              note: item.nota,
              preparedAt: item.fechaPreparado ?? command.fecha ?? fallback,
            ),
          );
      titles[orderId] = 'Mesa ${table.numero ?? table.id ?? '-'}';
      subtitles[orderId] = table.salon?.nombre ?? '';
    }
  }

  final result = grouped.entries.map((entry) {
    final dishes = [...entry.value]
      ..sort((a, b) => a.preparedAt.compareTo(b.preparedAt));
    return ReadyTableGroup(
      orderId: entry.key,
      title: titles[entry.key] ?? 'Mesa',
      subtitle: subtitles[entry.key] ?? '',
      dishes: dishes,
      waitingSince: dishes.first.preparedAt,
    );
  }).toList()..sort((a, b) => a.waitingSince.compareTo(b.waitingSince));
  return result;
}

class ReadyToServeNotifier extends StateNotifier<ReadyToServeState> {
  final RestaurantRepository repository;

  ReadyToServeNotifier({required this.repository})
    : super(const ReadyToServeState());

  Future<void> refresh(int officeId, {bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true, clearError: true);
    try {
      final now = DateTime.now();
      final formatter = DateFormat('dd-MM-yyyy');
      final commands = await repository.getCommands({
        'desde': formatter.format(now.subtract(const Duration(days: 1))),
        'hasta': formatter.format(now),
        'estadoComandaDetalle': 'PREPARADO',
        'estadoPedido': ['PENDIENTE', 'PREPARADO', 'PRECUENTA'],
        'idPuntoVenta': officeId,
      });
      if (!mounted) return;
      state = state.copyWith(
        groups: groupReadyCommands(commands),
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<void> serveDish(ReadyDish dish, int officeId) async {
    if (state.processingItemIds.contains(dish.itemId)) return;
    state = state.copyWith(
      processingItemIds: {...state.processingItemIds, dish.itemId},
    );
    try {
      await repository.updateCommandItemStatus(
        dish.commandId,
        dish.itemId,
        'DESPACHADO',
      );
      if (!mounted) return;
      _removeDishes({dish.itemId});
      await refresh(officeId, silent: true);
    } catch (error) {
      errorNotification(error.toString().replaceFirst('Exception: ', ''));
      await refresh(officeId, silent: true);
    } finally {
      if (mounted) {
        state = state.copyWith(
          processingItemIds: {...state.processingItemIds}..remove(dish.itemId),
        );
      }
    }
  }

  Future<void> serveTable(ReadyTableGroup group, int officeId) async {
    if (state.processingOrderIds.contains(group.orderId)) return;
    state = state.copyWith(
      processingOrderIds: {...state.processingOrderIds, group.orderId},
    );
    try {
      final byCommand = <int, List<int>>{};
      for (final dish in group.dishes) {
        byCommand.putIfAbsent(dish.commandId, () => []).add(dish.itemId);
      }
      await Future.wait(
        byCommand.entries.map(
          (entry) => repository.updateCommandItemsStatus(
            entry.key,
            entry.value,
            'DESPACHADO',
          ),
        ),
      );
      if (!mounted) return;
      _removeDishes(group.dishes.map((dish) => dish.itemId).toSet());
      await refresh(officeId, silent: true);
    } catch (error) {
      errorNotification(error.toString().replaceFirst('Exception: ', ''));
      await refresh(officeId, silent: true);
    } finally {
      if (mounted) {
        state = state.copyWith(
          processingOrderIds: {...state.processingOrderIds}
            ..remove(group.orderId),
        );
      }
    }
  }

  void _removeDishes(Set<int> itemIds) {
    final groups = state.groups
        .map(
          (group) => ReadyTableGroup(
            orderId: group.orderId,
            title: group.title,
            subtitle: group.subtitle,
            dishes: group.dishes
                .where((dish) => !itemIds.contains(dish.itemId))
                .toList(),
            waitingSince: group.waitingSince,
          ),
        )
        .where((group) => group.dishes.isNotEmpty)
        .toList();
    state = state.copyWith(groups: groups);
  }
}

class ReadyToServeState {
  final List<ReadyTableGroup> groups;
  final bool isLoading;
  final Set<int> processingItemIds;
  final Set<int> processingOrderIds;
  final String? error;

  const ReadyToServeState({
    this.groups = const [],
    this.isLoading = false,
    this.processingItemIds = const {},
    this.processingOrderIds = const {},
    this.error,
  });

  int get total => groups.fold(0, (sum, group) => sum + group.dishes.length);

  ReadyToServeState copyWith({
    List<ReadyTableGroup>? groups,
    bool? isLoading,
    Set<int>? processingItemIds,
    Set<int>? processingOrderIds,
    String? error,
    bool clearError = false,
  }) {
    return ReadyToServeState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      processingItemIds: processingItemIds ?? this.processingItemIds,
      processingOrderIds: processingOrderIds ?? this.processingOrderIds,
      error: clearError ? null : error ?? this.error,
    );
  }
}
