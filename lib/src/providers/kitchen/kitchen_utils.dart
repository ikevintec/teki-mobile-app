import 'package:flutter/material.dart';
import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail_group_option.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/providers/kitchen/kitchen_state.dart';

/// Color de identidad por vista: pendiente=gris, listos=verde,
/// servidos=azul, anulados=rojo. Se usa en las barras laterales de las
/// comandas y en las pestañas de filtro para que sea evidente qué se ve.
Color kitchenViewColor(KitchenView view) => switch (view) {
  KitchenView.pending => const Color(0xFF64748B),
  KitchenView.ready => const Color(0xFF16A34A),
  KitchenView.served => const Color(0xFF2B83DC),
  KitchenView.cancelled => const Color(0xFFDC2626),
};

const kitchenNextStatus = <String, String>{
  'PENDIENTE': 'PREPARACION',
  'PREPARACION': 'PREPARADO',
  'PREPARADO': 'DESPACHADO',
};

const kitchenPreviousStatus = <String, String>{
  'PREPARACION': 'PENDIENTE',
  'PREPARADO': 'PREPARACION',
  'DESPACHADO': 'PREPARADO',
};

const kitchenStatusLabels = <String, String>{
  'PENDIENTE': 'Por hacer',
  'PREPARACION': 'Preparando',
  'PREPARADO': 'Listo',
  'DESPACHADO': 'Servido',
  'CANCELADO': 'Anulado',
};

KitchenView? kitchenViewForStatus(String? status) => switch (status) {
  'PENDIENTE' || 'PREPARACION' => KitchenView.pending,
  'PREPARADO' => KitchenView.ready,
  'DESPACHADO' => KitchenView.served,
  'CANCELADO' => KitchenView.cancelled,
  _ => null,
};

bool kitchenProductInAreas(Product? product, List<int> areaIds) {
  final category = product?.categoria;
  final primary = category?.areaProduccion?.id;
  final secondary = category?.areaProduccionSecundaria?.id;
  return (primary != null && areaIds.contains(primary)) ||
      (secondary != null && areaIds.contains(secondary));
}

bool kitchenItemInAreas(CommandDetail item, List<int> areaIds) {
  if (areaIds.isEmpty || item.producto?.categoria?.areaProduccion == null) {
    return true;
  }
  return kitchenProductInAreas(item.producto, areaIds) ||
      (item.grupoProductoOpciones ?? const []).any(
        (option) => kitchenProductInAreas(option.producto, areaIds),
      );
}

bool kitchenMainProductInAreas(CommandDetail item, List<int> areaIds) {
  return areaIds.isEmpty ||
      item.producto?.categoria?.areaProduccion == null ||
      kitchenProductInAreas(item.producto, areaIds);
}

List<CommandDetailGroupOption> kitchenComplementsInAreas(
  CommandDetail item,
  List<int> areaIds,
) {
  return (item.grupoProductoOpciones ?? const []).where((option) {
    return areaIds.isEmpty ||
        option.producto?.categoria?.areaProduccion == null ||
        kitchenProductInAreas(option.producto, areaIds);
  }).toList();
}

bool kitchenItemMatchesMode(CommandDetail item, KitchenOrderMode mode) {
  return switch (mode) {
    KitchenOrderMode.all => true,
    KitchenOrderMode.dineIn => item.paraLlevar != true,
    KitchenOrderMode.takeaway => item.paraLlevar == true,
  };
}

bool _isToday(DateTime? value, DateTime now) {
  if (value == null) return false;
  final local = value.toLocal();
  return local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
}

List<CommandDetail> kitchenItemsForView(
  Command command,
  KitchenState state, {
  KitchenView? view,
}) {
  final selectedView = view ?? state.filters.view;
  final result = <CommandDetail>[];
  for (final item in command.items ?? const <CommandDetail>[]) {
    if (item.eliminado == true) continue;
    if (!kitchenItemInAreas(item, state.filters.productionAreaIds) ||
        !kitchenItemMatchesMode(item, state.filters.mode)) {
      continue;
    }

    final actualStatus = item.estadoComandaDetalle;
    final notice = item.id == null ? null : state.cancellationNotices[item.id];
    final retainedView = item.id == null ? null : state.retainedViews[item.id];
    final effectiveStatus = item.id == null
        ? actualStatus
        : (state.pendingStatuses[item.id] ?? actualStatus);

    final visible = selectedView == KitchenView.cancelled
        ? actualStatus == 'CANCELADO' &&
              _isToday(item.fechaAnulacion ?? command.fecha, state.now)
        : actualStatus != 'CANCELADO' &&
                  selectedView.statuses.contains(effectiveStatus) ||
              retainedView == selectedView ||
              notice?.previousView == selectedView;
    if (visible) result.add(item);
  }
  return result;
}

List<Command> kitchenCommandsForView(KitchenState state, {KitchenView? view}) {
  return state.commands
      .where(
        (command) => kitchenItemsForView(command, state, view: view).isNotEmpty,
      )
      .toList();
}

int kitchenCountForView(KitchenState state, KitchenView view) {
  if (view == KitchenView.cancelled) {
    return state.commands.fold(
      0,
      (total, command) =>
          total + kitchenItemsForView(command, state, view: view).length,
    );
  }
  return kitchenCommandsForView(state, view: view).length;
}

Duration kitchenElapsed(Command command, DateTime now) {
  final sent = command.fecha?.toLocal();
  if (sent == null) return Duration.zero;
  final elapsed = now.difference(sent);
  return elapsed.isNegative ? Duration.zero : elapsed;
}

String kitchenStopwatchLabel(Command command, DateTime now) {
  final elapsed = kitchenElapsed(command, now);
  final hours = elapsed.inHours;
  final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0
      ? '$hours:$minutes:$seconds'
      : '${elapsed.inMinutes}:$seconds';
}

String kitchenTimeBand(Command command, int maxMinutes, DateTime now) {
  final minutes = kitchenElapsed(command, now).inMinutes;
  final threshold = maxMinutes > 0 ? maxMinutes : 15;
  if (minutes >= threshold * 2) return 'late';
  if (minutes >= threshold) return 'warn';
  return 'ok';
}

String kitchenCommandTitle(Command command) {
  final order = command.pedido;
  if (order?.tipo == 'LOCAL' && order?.mesa?.numero != null) {
    return 'Mesa ${order!.mesa!.numero}';
  }
  final customer = order?.nombreCliente?.trim();
  if (customer != null && customer.isNotEmpty) return customer;
  final businessName = order?.cliente?.razonSocial?.trim();
  if (businessName != null && businessName.isNotEmpty) return businessName;
  return kitchenOrderTypeLabel(order?.tipo);
}

String kitchenCommandSubtitle(Command command) {
  final order = command.pedido;
  if (order?.tipo == 'LOCAL' && order?.mesa?.salon?.nombre != null) {
    return order!.mesa!.salon!.nombre!;
  }
  return kitchenOrderTypeLabel(order?.tipo);
}

String kitchenOrderTypeLabel(String? type) => switch (type) {
  'LOCAL' => 'Salón',
  'PEDIDO_FORANEO' => 'Delivery',
  'PEDIDO_ONLINE' => 'Pedido online',
  _ => 'Para llevar',
};

String kitchenQuantity(double? value) {
  if (value == null) return '0';
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
}

DateTime? kitchenStateTime(CommandDetail item) =>
    switch (item.estadoComandaDetalle) {
      'PREPARADO' => item.fechaPreparado,
      'DESPACHADO' => item.fechaDespachado,
      'CANCELADO' => item.fechaAnulacion,
      _ => null,
    };

bool kitchenWasCancelledAfterReady(CommandDetail item) =>
    item.estadoComandaDetalle == 'CANCELADO' &&
    (item.fechaPreparado != null || item.fechaDespachado != null);

String kitchenEmptyMessage(KitchenView view) => switch (view) {
  KitchenView.pending => 'Sin comandas pendientes. Todo al día.',
  KitchenView.ready => 'No hay platos listos por servir.',
  KitchenView.served => 'Todavía no se sirvió nada hoy.',
  KitchenView.cancelled => 'Sin platos anulados hoy.',
};
