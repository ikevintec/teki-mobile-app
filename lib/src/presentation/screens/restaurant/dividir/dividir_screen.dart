import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/check.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail.dart';
import 'package:teki_app/src/data/models/teki_model/order_restaurant.dart';
import 'package:teki_app/src/data/repositories/restaurant_repository_impl.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/restaurant/restaurant_provider.dart';
import 'package:teki_app/src/presentation/screens/restaurant/widgets/comanda_detail_item_tile.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/notifications.dart';

class _DragItem {
  final CommandDetail item;
  final int index;            // index within the source list
  final bool fromUnassigned;  // true = viene de sin asignar, false = viene de una cuenta
  final int? sourceCheckIndex; // solo cuando fromUnassigned == false

  _DragItem({
    required this.item,
    required this.index,
    required this.fromUnassigned,
    this.sourceCheckIndex,
  });
}

class LocalCheck {
  final List<CommandDetail> items;

  LocalCheck({List<CommandDetail>? items}) : items = items ?? [];

  double get total => items.fold(0, (s, d) => s + ((d.precioVenta ?? 0) * (d.cantidad ?? 1)));

  LocalCheck copyWith({List<CommandDetail>? items}) => LocalCheck(items: items ?? this.items);
}

class DividirScreen extends ConsumerStatefulWidget {
  final OrderRestaurant order;

  const DividirScreen({super.key, required this.order});

  @override
  ConsumerState<DividirScreen> createState() => _DividirScreenState();
}

class _DividirScreenState extends ConsumerState<DividirScreen> {
  late List<CommandDetail> _unassigned;
  late List<LocalCheck> _checks;
  bool _isSubmitting = false;
  bool _isDragging = false;
  // Id del item que se está separando en el servidor (muestra spinner en su tile).
  int? _expandingItemId;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _unassigned = _getAllItems(widget.order);
    _checks = [LocalCheck(), LocalCheck()];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Líneas completas de la orden, con sus objetos originales (id real,
  /// opciones de grupo, etc.). Para repartir unidades de una línea multi-
  /// cantidad se usa "Separar" (endpoint expand del servidor), igual que la web.
  List<CommandDetail> _getAllItems(OrderRestaurant order) {
    final List<CommandDetail> result = [];
    for (final comanda in (order.comandas ?? [])) {
      for (final item in (comanda.items ?? [])) {
        if (item.cuenta != null) continue;
        // eliminado=true son líneas reemplazadas por el servidor (p.ej. al
        // separar): no se muestran. Las CANCELADO sí, como no arrastrables.
        if (item.eliminado == true) continue;
        result.add(item);
      }
    }
    return result;
  }

  /// Separa una línea multi-cantidad en N líneas de cantidad 1 usando el
  /// endpoint expand del servidor (ids reales), y reconstruye el estado local
  /// conservando las asignaciones existentes por id.
  Future<void> _separarItem(CommandDetail item) async {
    if (_expandingItemId != null || item.id == null) return;
    final qty = (item.cantidad ?? 1).toInt();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Separar item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(
          '¿Está seguro de separar "${item.producto?.nombre ?? '-'}" en $qty items?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Separar', style: TextStyle(color: ColorSchema.primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _expandingItemId = item.id);
    // Capturar antes de los await: tras desmontar el widget, ref deja de ser válido.
    final pvId = ref.read(sesionProvider).office?.id;
    final notifier = ref.read(restaurantProvider.notifier);
    try {
      await RestaurantRepositoryImpl().expandCommandItem(item.id!);
      if (pvId != null) await notifier.reload(pvId);
      if (!mounted) return;
      final updatedOrder = ref.read(restaurantProvider).orders.firstWhere(
            (o) => o.id == widget.order.id,
            orElse: () => widget.order,
          );
      _rebuildFromOrder(updatedOrder);
    } catch (e) {
      errorNotification(e.toString());
    } finally {
      if (mounted) setState(() => _expandingItemId = null);
    }
  }

  /// Reconstruye sin asignar + cuentas a partir de la orden recargada:
  /// los items ya asignados se re-vinculan por id; el resto queda sin asignar.
  void _rebuildFromOrder(OrderRestaurant order) {
    final byId = <int?, CommandDetail>{
      for (final i in _getAllItems(order)) i.id: i,
    };
    setState(() {
      _checks = _checks
          .map((c) => c.copyWith(
                items: c.items
                    .map((old) => byId.remove(old.id))
                    .whereType<CommandDetail>()
                    .toList(),
              ))
          .toList();
      _unassigned = byId.values.toList();
    });
  }

  void _onDropToCheck(_DragItem drag, int targetCheckIndex) {
    if (!drag.fromUnassigned && drag.sourceCheckIndex == targetCheckIndex) return;
    setState(() {
      final item = drag.item;
      // Quitar del origen
      if (drag.fromUnassigned) {
        _unassigned = List.from(_unassigned)..removeAt(drag.index);
      } else {
        final srcItems = List<CommandDetail>.from(_checks[drag.sourceCheckIndex!].items)
          ..removeAt(drag.index);
        _checks = List.from(_checks)..[drag.sourceCheckIndex!] = _checks[drag.sourceCheckIndex!].copyWith(items: srcItems);
      }
      // Agregar al destino
      final destItems = List<CommandDetail>.from(_checks[targetCheckIndex].items)..add(item);
      _checks = List.from(_checks)..[targetCheckIndex] = _checks[targetCheckIndex].copyWith(items: destItems);
    });
  }

  void _onDropToUnassigned(_DragItem drag) {
    if (drag.fromUnassigned) return;
    setState(() {
      final srcItems = List<CommandDetail>.from(_checks[drag.sourceCheckIndex!].items)
        ..removeAt(drag.index);
      _checks = List.from(_checks)..[drag.sourceCheckIndex!] = _checks[drag.sourceCheckIndex!].copyWith(items: srcItems);
      _unassigned = List.from(_unassigned)..add(drag.item);
    });
  }

  void _moveToUnassigned(int checkIndex, int itemIndex) {
    setState(() {
      final item = _checks[checkIndex].items[itemIndex];
      final updatedItems = List<CommandDetail>.from(_checks[checkIndex].items)..removeAt(itemIndex);
      _checks = List.from(_checks)..[checkIndex] = _checks[checkIndex].copyWith(items: updatedItems);
      _unassigned = List.from(_unassigned)..add(item);
    });
  }

  void _addCheck() {
    setState(() {
      _checks = List.from(_checks)..add(LocalCheck());
    });
  }

  void _deleteCheck(int checkIndex) {
    setState(() {
      final items = List<CommandDetail>.from(_checks[checkIndex].items);
      final newChecks = List<LocalCheck>.from(_checks)..removeAt(checkIndex);
      _checks = newChecks;
      _unassigned = List.from(_unassigned)..addAll(items);
    });
  }

  void _autoScroll(double dy) {
    if (!_scrollController.hasClients) return;
    final screenHeight = MediaQuery.of(context).size.height;
    const zone = 140.0;
    const speed = 12.0;
    final maxOffset = _scrollController.position.maxScrollExtent;

    if (dy > screenHeight - zone && _scrollController.offset < maxOffset) {
      _scrollController.jumpTo(
        (_scrollController.offset + speed).clamp(0.0, maxOffset),
      );
    } else if (dy < zone + kToolbarHeight && _scrollController.offset > 0) {
      _scrollController.jumpTo(
        (_scrollController.offset - speed).clamp(0.0, maxOffset),
      );
    }
  }

  Future<void> _saveChecks() async {
    final emptyChecks = _checks.where((c) => c.items.isEmpty).toList();
    if (emptyChecks.isNotEmpty) {
      warningNotification('Cada cuenta debe tener al menos 1 producto');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = RestaurantRepositoryImpl();
      // Cada item es una línea real del servidor (id único), por lo que se
      // envía tal cual, sin reagrupar en el cliente.
      final checksToSend = _checks
          .where((c) => c.items.isNotEmpty)
          .map((c) => Check(items: c.items))
          .toList();

      final pvId = ref.read(sesionProvider).office?.id;
      final notifier = ref.read(restaurantProvider.notifier);

      await repo.saveChecks(widget.order.id!, checksToSend);

      if (mounted) Navigator.of(context).pop();
      successNotification('Cuentas guardadas');
      if (pvId != null) notifier.reload(pvId);
    } catch (e) {
      setState(() => _isSubmitting = false);
      errorNotification(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: ColorSchema.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'Mesa ${order.mesa?.numero ?? order.mesa?.id} · Dividir cuenta',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        actions: [
          TextButton.icon(
            onPressed: _addCheck,
            icon: const Icon(Icons.add, color: Colors.white, size: 18),
            label: const Text(
              'Cuenta',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
      body: Listener(
        onPointerMove: (event) {
          if (_isDragging) _autoScroll(event.position.dy);
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUnassignedSection(),
              const SizedBox(height: 6),
              ..._checks.asMap().entries.map((e) => _buildCheckDropZone(e.key, e.value)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Unassigned section ────────────────────────────────────────────────────

  Widget _buildUnassignedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.grey.shade700,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            children: [
              const Icon(Icons.drag_indicator, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Sin asignar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_unassigned.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              if (_unassigned.isEmpty)
                const Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
            ],
          ),
        ),
        // Items — también es DragTarget para recibir items de cuentas
        DragTarget<_DragItem>(
          onWillAcceptWithDetails: (d) => !d.data.fromUnassigned,
          onAcceptWithDetails: (d) => _onDropToUnassigned(d.data),
          builder: (context, candidateData, _) {
            final hovering = candidateData.isNotEmpty;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: hovering ? Colors.grey.shade100 : Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                border: Border.all(
                  color: hovering ? Colors.grey.shade500 : Colors.grey.shade200,
                  width: hovering ? 2 : 1,
                ),
              ),
              child: _unassigned.isEmpty && !hovering
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'Todos los productos han sido asignados ✓',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        ..._unassigned.asMap().entries.map((e) => _buildDraggableItem(e.key, e.value)),
                        if (hovering)
                          Container(
                            margin: const EdgeInsets.all(10),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.undo, size: 14, color: Colors.grey),
                                SizedBox(width: 4),
                                Text('Devolver aquí', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                      ],
                    ),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDraggableItem(int index, CommandDetail item) {
    final isLast = index == _unassigned.length - 1;

    // Cancelled items are shown as non-draggable, visually struck-through.
    if (ComandaDetailStatus.isCancelledItem(item)) {
      return _buildItemTile(item, isLast: isLast, isCancelled: true);
    }

    final canSeparar = (item.cantidad ?? 1) > 1 && item.id != null;

    return LongPressDraggable<_DragItem>(
      data: _DragItem(item: item, index: index, fromUnassigned: true),
      delay: const Duration(milliseconds: 150),
      onDragStarted: () => setState(() => _isDragging = true),
      onDragEnd: (_) => setState(() => _isDragging = false),
      onDraggableCanceled: (_, __) => setState(() => _isDragging = false),
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 240,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ColorSchema.primaryColor, width: 2),
          ),
          child: Row(
            children: [
              const Icon(Icons.drag_indicator, color: ColorSchema.primaryColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${(item.cantidad ?? 1).toInt()}x ${item.producto?.nombre ?? '-'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'S/. ${((item.precioVenta ?? 0) * (item.cantidad ?? 1)).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12, color: ColorSchema.primaryColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _buildItemTile(item, isLast: isLast),
      ),
      child: _buildItemTile(
        item,
        isLast: isLast,
        onSeparar: canSeparar ? () => _separarItem(item) : null,
      ),
    );
  }

  Widget _buildItemTile(
    CommandDetail item, {
    bool isLast = false,
    VoidCallback? onUndo,
    VoidCallback? onSeparar,
    bool isCancelled = false,
  }) {
    final textDecor = isCancelled ? TextDecoration.lineThrough : TextDecoration.none;
    final textColor = isCancelled ? Colors.red.shade400 : Colors.black87;
    final subColor = isCancelled ? Colors.red.shade300 : ColorSchema.primaryColor;

    return Container(
      color: isCancelled ? Colors.red.shade50 : null,
      decoration: isCancelled
          ? null
          : BoxDecoration(
              border: isLast
                  ? null
                  : Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Icon(
              isCancelled ? Icons.block_rounded : Icons.drag_indicator,
              color: isCancelled ? Colors.red.shade300 : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${(item.cantidad ?? 1).toInt()}x ${item.producto?.nombre ?? '-'}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: textColor,
                      decoration: textDecor,
                      decorationColor: Colors.red.shade400,
                    ),
                  ),
                  Text(
                    'S/. ${((item.precioVenta ?? 0) * (item.cantidad ?? 1)).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: subColor,
                      decoration: textDecor,
                      decorationColor: Colors.red.shade300,
                    ),
                  ),
                ],
              ),
            ),
            if (isCancelled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  'Cancelado',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade400,
                  ),
                ),
              )
            else if (onUndo != null)
              GestureDetector(
                onTap: onUndo,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.undo, size: 14, color: Colors.red.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'Quitar',
                        style: TextStyle(fontSize: 11, color: Colors.red.shade400, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              )
            else if (onSeparar != null)
              _expandingItemId == item.id
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ColorSchema.primaryColor,
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: onSeparar,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: ColorSchema.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: ColorSchema.primaryColor.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.call_split_rounded, size: 14, color: ColorSchema.primaryColor),
                            SizedBox(width: 4),
                            Text(
                              'Separar',
                              style: TextStyle(fontSize: 11, color: ColorSchema.primaryColor, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
          ],
        ),
      ),
    );
  }

  // ── Check drop zone ───────────────────────────────────────────────────────

  Widget _buildCheckDropZone(int checkIndex, LocalCheck check) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DragTarget<_DragItem>(
        onWillAcceptWithDetails: (d) => d.data.fromUnassigned || d.data.sourceCheckIndex != checkIndex,
        onAcceptWithDetails: (details) => _onDropToCheck(details.data, checkIndex),
        builder: (context, candidateData, _) {
          final hovering = candidateData.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hovering ? ColorSchema.primaryColor : Colors.transparent,
                width: 2,
              ),
              color: hovering ? ColorSchema.primaryColor.withValues(alpha: 0.05) : Colors.transparent,
            ),
            child: Column(
              children: [
                // Check header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: hovering ? ColorSchema.primaryColor : ColorSchema.primaryColor.withValues(alpha: 0.88),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Cuenta ${checkIndex + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${check.items.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'S/. ${check.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_checks.length > 1) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _deleteCheck(checkIndex),
                          child: const Icon(Icons.delete_outline, color: Colors.white70, size: 18),
                        ),
                      ],
                    ],
                  ),
                ),
                // Drop content
                Container(
                  constraints: const BoxConstraints(minHeight: 70),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                    border: Border(
                      left: BorderSide(color: hovering ? ColorSchema.primaryColor : Colors.grey.shade200),
                      right: BorderSide(color: hovering ? ColorSchema.primaryColor : Colors.grey.shade200),
                      bottom: BorderSide(color: hovering ? ColorSchema.primaryColor : Colors.grey.shade200),
                    ),
                  ),
                  child: check.items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 22),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  hovering ? Icons.add_circle_rounded : Icons.touch_app_outlined,
                                  color: hovering ? ColorSchema.primaryColor : Colors.grey.shade400,
                                  size: 30,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  hovering ? '¡Suelta aquí!' : 'Arrastra productos aquí',
                                  style: TextStyle(
                                    color: hovering ? ColorSchema.primaryColor : Colors.grey.shade400,
                                    fontSize: 13,
                                    fontWeight: hovering ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            ...check.items.asMap().entries.map((ie) {
                              final isLast = ie.key == check.items.length - 1 && !hovering;
                              final dragData = _DragItem(
                                item: ie.value,
                                index: ie.key,
                                fromUnassigned: false,
                                sourceCheckIndex: checkIndex,
                              );
                              return LongPressDraggable<_DragItem>(
                                data: dragData,
                                delay: const Duration(milliseconds: 150),
                                onDragStarted: () => setState(() => _isDragging = true),
                                onDragEnd: (_) => setState(() => _isDragging = false),
                                onDraggableCanceled: (_, __) => setState(() => _isDragging = false),
                                feedback: Material(
                                  elevation: 8,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 240,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: ColorSchema.primaryColor, width: 2),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.drag_indicator, color: ColorSchema.primaryColor, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${(ie.value.cantidad ?? 1).toInt()}x ${ie.value.producto?.nombre ?? '-'}',
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'S/. ${((ie.value.precioVenta ?? 0) * (ie.value.cantidad ?? 1)).toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 12, color: ColorSchema.primaryColor, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.35,
                                  child: _buildItemTile(ie.value, isLast: isLast),
                                ),
                                child: _buildItemTile(
                                  ie.value,
                                  isLast: isLast,
                                  onUndo: () => _moveToUnassigned(checkIndex, ie.key),
                                ),
                              );
                            }),
                            if (hovering)
                              Container(
                                margin: const EdgeInsets.all(10),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: ColorSchema.primaryColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: ColorSchema.primaryColor.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add, size: 14, color: ColorSchema.primaryColor),
                                    SizedBox(width: 4),
                                    Text(
                                      'Agregar aquí',
                                      style: TextStyle(
                                        color: ColorSchema.primaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _saveChecks,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorSchema.primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _checks.any((c) => c.items.isEmpty)
                          ? 'Hay ${_checks.where((c) => c.items.isEmpty).length} cuenta(s) vacía(s)'
                          : 'Guardar ${_checks.length} cuenta(s)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
