import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail.dart';
import 'package:teki_app/src/providers/kitchen/kitchen_state.dart';
import 'package:teki_app/src/providers/kitchen/kitchen_utils.dart';

typedef KitchenItemAction =
    Future<void> Function(Command command, CommandDetail item);

class KitchenOrderCard extends StatefulWidget {
  final Command command;
  final KitchenState state;
  final KitchenItemAction onItemTap;
  final Future<void> Function(Command command) onAdvanceAll;
  final ValueChanged<int> onCancellationsSeen;

  const KitchenOrderCard({
    super.key,
    required this.command,
    required this.state,
    required this.onItemTap,
    required this.onAdvanceAll,
    required this.onCancellationsSeen,
  });

  @override
  State<KitchenOrderCard> createState() => _KitchenOrderCardState();
}

class _KitchenOrderCardState extends State<KitchenOrderCard> {
  bool? _cancelledExpanded;

  KitchenView get _view => widget.state.filters.view;

  List<CommandDetail> get _visibleItems =>
      kitchenItemsForView(widget.command, widget.state);

  List<CommandDetail> get _cancelledItems {
    if (_view == KitchenView.cancelled) return const [];
    return (widget.command.items ?? const <CommandDetail>[]).where((item) {
      if (item.eliminado == true || item.estadoComandaDetalle != 'CANCELADO') {
        return false;
      }
      if (!kitchenItemInAreas(item, widget.state.filters.productionAreaIds)) {
        return false;
      }
      final notice = item.id == null
          ? null
          : widget.state.cancellationNotices[item.id];
      return notice?.previousView != _view;
    }).toList();
  }

  bool get _showCancelled =>
      _cancelledExpanded ?? widget.state.filters.showCancelled;

  List<CommandDetail> get _actionableItems => _visibleItems.where((item) {
    return item.id != null &&
        kitchenNextStatus.containsKey(item.estadoComandaDetalle) &&
        !widget.state.busyItemIds.contains(item.id);
  }).toList();

  int get _noticeCount => widget.state.cancellationNotices.values
      .where(
        (notice) =>
            notice.commandId == widget.command.id &&
            notice.previousView == _view,
      )
      .length;

  Color get _accentColor {
    final highlight = widget.state.highlights[widget.command.id];
    if (highlight?.type == KitchenHighlightType.cancelled) {
      return const Color(0xFFDC2626);
    }
    if (highlight?.type == KitchenHighlightType.newOrder) {
      return const Color(0xFF2B83DC);
    }
    // La barra lateral toma el color de la vista filtrada. Solo las comandas
    // pendientes escalan por tiempo (ámbar/rojo) porque ahí importa la urgencia.
    if (_view == KitchenView.pending) {
      final band = kitchenTimeBand(
        widget.command,
        widget.state.filters.preparationMinutes,
        widget.state.now,
      );
      if (band == 'late') return const Color(0xFFDC2626);
      if (band == 'warn') return const Color(0xFFF59E0B);
    }
    return kitchenViewColor(_view);
  }

  Color get _headerColor {
    final accent = _accentColor;
    if (accent == const Color(0xFFF59E0B)) return const Color(0xFFFFF7E6);
    if (accent == const Color(0xFFDC2626)) return const Color(0xFFFEE2E2);
    if (accent == const Color(0xFF2B83DC)) return const Color(0xFFEFF6FF);
    if (accent == const Color(0xFF16A34A)) return const Color(0xFFF0FDF4);
    return const Color(0xFFF8FAFC);
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _visibleItems;
    final accent = _accentColor;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          // Elevación neutra: despega la card del fondo.
          const BoxShadow(
            color: Color(0x16000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
          // Halo tenue con el color de estado para separar cards vecinas.
          BoxShadow(
            color: accent.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                _buildMetadata(),
                if (widget.command.pedido?.estado == 'CANCELADO')
                  _OrderNote(
                    icon: Icons.block_rounded,
                    text: _cancelledOrderText,
                    danger: true,
                  )
                else if ((widget.command.pedido?.observacion ?? '')
                    .trim()
                    .isNotEmpty)
                  _OrderNote(
                    icon: Icons.comment_outlined,
                    text: widget.command.pedido!.observacion!,
                  ),
                for (var index = 0; index < visibleItems.length; index++) ...[
                  if (index > 0)
                    const Divider(height: 1, indent: 12, endIndent: 12),
                  KitchenItemTile(
                    item: visibleItems[index],
                    state: widget.state,
                    onTap: () =>
                        widget.onItemTap(widget.command, visibleItems[index]),
                  ),
                ],
                if (_cancelledItems.isNotEmpty) _buildCancelledSection(),
                if (_view != KitchenView.cancelled) _buildFooter(),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: ColoredBox(
                color: accent,
                child: const SizedBox(width: 5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final band = kitchenTimeBand(
      widget.command,
      widget.state.filters.preparationMinutes,
      widget.state.now,
    );
    return Container(
      color: _headerColor,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Icon(_orderIcon, color: _accentColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kitchenCommandTitle(widget.command),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  kitchenCommandSubtitle(widget.command),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _timeLabel,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color:
                      _view == KitchenView.served ||
                          _view == KitchenView.cancelled
                      ? const Color(0xFF64748B)
                      : _accentColor,
                ),
              ),
              if (_view != KitchenView.served &&
                  _view != KitchenView.cancelled &&
                  band != 'ok')
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      band == 'late' ? 'Muy atrasada' : 'Atrasada',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _accentColor,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFAFAFA),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children:
            [
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Comanda '),
                        TextSpan(
                          text: '#${widget.command.numeroComanda ?? '-'}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  Text('Pedido #${widget.command.pedido?.numeroOrden ?? '-'}'),
                  if ((widget.command.usuario ?? '').isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 14),
                        const SizedBox(width: 3),
                        Text(widget.command.usuario!),
                      ],
                    ),
                ]
                .map(
                  (child) => DefaultTextStyle(
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                    child: child,
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildCancelledSection() {
    return Column(
      children: [
        const Divider(height: 1),
        InkWell(
          onTap: () => setState(() => _cancelledExpanded = !_showCancelled),
          child: Container(
            color: const Color(0xFFFFF5F5),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                const Icon(
                  Icons.block_rounded,
                  color: Color(0xFFB91C1C),
                  size: 17,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    '${_cancelledItems.length} ${_cancelledItems.length == 1 ? 'plato anulado' : 'platos anulados'}',
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  _showCancelled
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFFB91C1C),
                ),
              ],
            ),
          ),
        ),
        if (_showCancelled)
          for (final item in _cancelledItems)
            KitchenItemTile(item: item, state: widget.state),
      ],
    );
  }

  Widget _buildFooter() {
    final progress = _progress;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              progress.$1,
              style: TextStyle(
                fontSize: 12,
                fontWeight: progress.$2 ? FontWeight.w800 : FontWeight.w500,
                color: progress.$2
                    ? const Color(0xFF15803D)
                    : const Color(0xFF6B7280),
              ),
            ),
          ),
          if (_noticeCount > 0)
            FilledButton.icon(
              onPressed: widget.command.id == null
                  ? null
                  : () => widget.onCancellationsSeen(widget.command.id!),
              icon: const Icon(Icons.check_rounded, size: 17),
              label: Text(
                _noticeCount == 1 ? 'Visto' : 'Vistos ($_noticeCount)',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                visualDensity: VisualDensity.compact,
              ),
            )
          else if (_actionableItems.length > 1 &&
              (_view == KitchenView.pending || _view == KitchenView.ready))
            FilledButton.icon(
              onPressed: () => widget.onAdvanceAll(widget.command),
              icon: Icon(
                _view == KitchenView.pending
                    ? Icons.done_all_rounded
                    : Icons.send_rounded,
                size: 17,
              ),
              label: Text(
                _view == KitchenView.pending ? 'Todo listo' : 'Servir todo',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _view == KitchenView.pending
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF2B83DC),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }

  (String, bool) get _progress {
    final alive = (widget.command.items ?? const <CommandDetail>[])
        .where(
          (item) =>
              item.eliminado != true &&
              item.estadoComandaDetalle != 'CANCELADO' &&
              kitchenItemInAreas(item, widget.state.filters.productionAreaIds),
        )
        .toList();
    final served = alive
        .where((item) => item.estadoComandaDetalle == 'DESPACHADO')
        .length;
    if (alive.isNotEmpty && served == alive.length) {
      return ('Comanda completa', true);
    }
    if (_view == KitchenView.served) {
      return ('$served de ${alive.length} servidos', false);
    }
    final ready = alive
        .where(
          (item) =>
              item.estadoComandaDetalle == 'PREPARADO' ||
              item.estadoComandaDetalle == 'DESPACHADO',
        )
        .length;
    return ('$ready de ${alive.length} listos', false);
  }

  String get _timeLabel {
    if (_view == KitchenView.cancelled) {
      return widget.command.fecha == null
          ? '--:--'
          : DateFormat('HH:mm').format(widget.command.fecha!.toLocal());
    }
    if (_view == KitchenView.served) {
      final servedDates =
          _visibleItems
              .map((item) => item.fechaDespachado)
              .whereType<DateTime>()
              .toList()
            ..sort();
      if (servedDates.isEmpty || widget.command.fecha == null) return 'Servido';
      final minutes = servedDates.last
          .difference(widget.command.fecha!)
          .inMinutes;
      return '${minutes.clamp(0, 999)} min';
    }
    return kitchenStopwatchLabel(widget.command, widget.state.now);
  }

  IconData get _orderIcon => switch (widget.command.pedido?.tipo) {
    'LOCAL' => Icons.restaurant_rounded,
    'PEDIDO_FORANEO' || 'PEDIDO_ONLINE' => Icons.delivery_dining_rounded,
    _ => Icons.shopping_bag_outlined,
  };

  String get _cancelledOrderText {
    final order = widget.command.pedido;
    final reason = (order?.observacion ?? order?.motivoRechazo ?? '').trim();
    return reason.isEmpty ? 'Pedido anulado' : 'Pedido anulado · $reason';
  }
}

class KitchenItemTile extends StatelessWidget {
  final CommandDetail item;
  final KitchenState state;
  final VoidCallback? onTap;

  const KitchenItemTile({
    super.key,
    required this.item,
    required this.state,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final itemId = item.id;
    final status = itemId == null
        ? item.estadoComandaDetalle
        : (state.pendingStatuses[itemId] ?? item.estadoComandaDetalle);
    final busy = itemId != null && state.busyItemIds.contains(itemId);
    final canAdvance =
        onTap != null &&
        kitchenNextStatus.containsKey(item.estadoComandaDetalle) &&
        !busy;
    final mainVisible = kitchenMainProductInAreas(
      item,
      state.filters.productionAreaIds,
    );
    final complements = kitchenComplementsInAreas(
      item,
      state.filters.productionAreaIds,
    );

    return Semantics(
      button: canAdvance,
      label:
          '${item.producto?.nombre ?? 'Plato'}, ${kitchenStatusLabels[status] ?? status}',
      child: Material(
        color: _background(status),
        child: InkWell(
          onTap: canAdvance ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 36,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: kitchenQuantity(item.cantidad),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const TextSpan(
                          text: 'x',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              '${mainVisible ? '' : 'de '}${item.producto?.nombre ?? 'Producto'}',
                              style: TextStyle(
                                fontSize: mainVisible ? 14 : 12.5,
                                fontWeight: FontWeight.w700,
                                color: status == 'CANCELADO'
                                    ? const Color(0xFF6B7280)
                                    : const Color(0xFF1F2937),
                                decoration: status == 'CANCELADO'
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          if (item.paraLlevar == true)
                            const _SmallChip(
                              label: 'Para llevar',
                              background: Color(0xFFE0F2FE),
                              foreground: Color(0xFF075985),
                            ),
                        ],
                      ),
                      if (mainVisible &&
                          (item.producto?.detalle ?? '').isNotEmpty)
                        Text(
                          item.producto!.detalle!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      if (mainVisible)
                        for (final preparation
                            in item.preparacionProductoOpciones ?? const [])
                          Text(
                            '${preparation.nombrePreparacion}: ${preparation.nombreOpcion}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF374151),
                            ),
                          ),
                      for (final option in complements)
                        Text(
                          '${kitchenQuantity(option.cantidad)}x ${option.nombreOpcion ?? ''} (${option.nombreGrupo ?? ''})',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF374151),
                          ),
                        ),
                      if (status != 'CANCELADO' &&
                          (item.nota ?? '').trim().isNotEmpty)
                        _ItemNote(
                          icon: Icons.edit_note_rounded,
                          text: item.nota!,
                        ),
                      if (status == 'CANCELADO' &&
                          (item.motivoAnulacion ?? '').trim().isNotEmpty)
                        _ItemNote(
                          icon: Icons.block_rounded,
                          text: item.motivoAnulacion!,
                          danger: true,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 74,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (busy)
                        const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      else
                        Text(
                          kitchenStatusLabels[status] ?? status ?? '',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: _statusColor(status),
                          ),
                        ),
                      if (!busy && kitchenStateTime(item) != null)
                        Text(
                          DateFormat(
                            'HH:mm',
                          ).format(kitchenStateTime(item)!.toLocal()),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      if (!busy && canAdvance)
                        Text(
                          _tapHint(item.estadoComandaDetalle),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      if (kitchenWasCancelledAfterReady(item))
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: _SmallChip(
                            label: 'Después de listo',
                            background: Color(0xFFFEE2E2),
                            foreground: Color(0xFF991B1B),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _background(String? status) => switch (status) {
    'PREPARACION' => const Color(0xFFFFF7E6),
    'PREPARADO' => const Color(0xFFECFDF3),
    'CANCELADO' => const Color(0xFFFFF5F5),
    _ => Colors.white,
  };

  Color _statusColor(String? status) => switch (status) {
    'PREPARACION' => const Color(0xFFB45309),
    'PREPARADO' => const Color(0xFF15803D),
    'DESPACHADO' => const Color(0xFF2B83DC),
    'CANCELADO' => const Color(0xFFB91C1C),
    _ => const Color(0xFF64748B),
  };

  String _tapHint(String? status) => switch (status) {
    'PENDIENTE' => 'Toca para empezar',
    'PREPARACION' => 'Toca cuando esté listo',
    'PREPARADO' => 'Toca para servir',
    _ => '',
  };
}

class _OrderNote extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool danger;

  const _OrderNote({
    required this.icon,
    required this.text,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: danger ? const Color(0xFFFFF1F2) : const Color(0xFFFEF9C3),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: danger ? const Color(0xFF9F1239) : const Color(0xFF713F12),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: danger
                    ? const Color(0xFF9F1239)
                    : const Color(0xFF713F12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemNote extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool danger;

  const _ItemNote({
    required this.icon,
    required this.text,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: danger ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(5),
        border: Border(
          left: BorderSide(
            color: danger ? const Color(0xFFDC2626) : const Color(0xFFF59E0B),
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: danger ? const Color(0xFF991B1B) : const Color(0xFF78350F),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: danger
                    ? const Color(0xFF991B1B)
                    : const Color(0xFF78350F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _SmallChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: foreground,
        ),
      ),
    );
  }
}
