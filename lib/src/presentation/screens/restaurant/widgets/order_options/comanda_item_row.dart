import 'package:flutter/material.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail.dart';
import 'package:teki_app/src/presentation/screens/restaurant/widgets/comanda_detail_item_tile.dart';
import 'package:teki_app/src/presentation/screens/restaurant/widgets/item_action_bottom_sheet.dart';

// ─── Comanda item row with status colors, payment badge, action button ────────

class CommandaItemRow extends StatefulWidget {
  final CommandDetail item;
  final void Function(double? cantidad)? onServir;
  final void Function(String? motivo, double? cantidad)? onAnular;
  final bool showStatus;

  /// La orden completa ya fue pagada: los items se muestran como pagados
  /// aunque su cuenta individual no traiga el flag (pago directo sin dividir).
  final bool orderPagado;

  const CommandaItemRow({
    super.key,
    required this.item,
    this.onServir,
    this.onAnular,
    this.showStatus = true,
    this.orderPagado = false,
  });

  @override
  State<CommandaItemRow> createState() => CommandaItemRowState();
}

class CommandaItemRowState extends State<CommandaItemRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: 4).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _showMotivoDialog(BuildContext context, String motivo) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 100),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 16, color: Colors.red.shade400),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Motivo de anulación',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Text(motivo, style: const TextStyle(fontSize: 13)),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isCancelled = ComandaDetailStatus.isCancelledItem(item);
    final status = item.estadoComandaDetalle?.toUpperCase() ?? ComandaDetailStatus.pendiente;
    final isPagado = widget.orderPagado || item.cuenta?.pagado == true;
    final hasActions =
        !isCancelled && !isPagado && (widget.onServir != null || widget.onAnular != null);
    final grupoOpciones =
        (item.grupoProductoOpciones ?? []).where((o) => o.eliminado != true).toList();
    final hasGroups = grupoOpciones.isNotEmpty;

    final textDecor = isCancelled ? TextDecoration.lineThrough : TextDecoration.none;
    final mainColor = isCancelled ? Colors.red.shade400 : Colors.black87;
    final bgColor = Colors.white;
    final borderAccent = isCancelled
        ? Colors.red.shade300
        : isPagado
            ? const Color(0xFF2E7D32)
            : statusBorderColor(status);
    final total = (item.precioVenta ?? 0) * (item.cantidad ?? 1);

    return GestureDetector(
      onTap: hasActions
          ? () => ItemActionBottomSheet.show(
                context,
                item: item,
                status: status,
                onServir: widget.onServir,
                onAnular: widget.onAnular,
              )
          : null,

      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            left: BorderSide(color: borderAccent, width: 3),
            bottom: BorderSide(color: Colors.grey.shade300, width: 1.0),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // ── Row 1: pagado + status (left) · arrow (right) ─────────────
          Row(
            children: [
              if (!isCancelled) ...[
                if (widget.showStatus && !isPagado && status != ComandaDetailStatus.pendiente) ...[
                  ComandaStatusBadge(status: status, fontSize: 8),
                  const SizedBox(width: 4),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPagado ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isPagado ? 'Pagado' : 'Por pagar',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isPagado ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (hasActions)
                AnimatedBuilder(
                  animation: _bounceAnim,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(_bounceAnim.value, 0),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: borderAccent,
                    ),
                  ),
                ),
              if (isCancelled && (item.motivoAnulacion?.isNotEmpty == true))
                GestureDetector(
                  onTap: () => _showMotivoDialog(context, item.motivoAnulacion!),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(Icons.chat_bubble_outline, size: 13, color: Colors.red.shade300),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          // ── Row 2: qty + name + price ──────────────────────────────────
          Row(
            children: [
              Text(
                '${item.cantidad?.toInt() ?? 1}x',
                style: TextStyle(
                  color: isCancelled ? Colors.red.shade400 : Colors.grey.shade600,
                  fontSize: isCancelled ? 11 : 13,
                  fontWeight: FontWeight.w600,
                  decoration: textDecor,
                  decorationColor: Colors.red.shade400,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.producto?.nombre ?? '-',
                  style: TextStyle(
                    fontSize: isCancelled ? 11 : 13,
                    fontWeight: FontWeight.w500,
                    color: mainColor,
                    decoration: textDecor,
                    decorationColor: Colors.red.shade400,
                  ),
                ),
              ),
              Text(
                'S/. ${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: isCancelled ? 11 : 13,
                  fontWeight: FontWeight.w600,
                  color: mainColor,
                  decoration: textDecor,
                  decorationColor: Colors.red.shade400,
                ),
              ),
            ],
          ),
          // ── Group options (expanded) ───────────────────────────────────
          if (hasGroups) ...[
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: grupoOpciones.map((o) {
                  final subColor = isCancelled ? Colors.red.shade300 : Colors.grey.shade600;
                  final optPrice = (o.precio ?? 0) * (o.cantidad ?? 1);
                  final name = o.nombreOpcion ?? o.nombreGrupo ?? '-';
                  return Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Icon(Icons.subdirectory_arrow_right_rounded,
                            size: 11, color: Colors.grey.shade400),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${(o.cantidad ?? 1).toInt()}x $name',
                            style: TextStyle(
                              fontSize: 11,
                              color: subColor,
                              decoration: textDecor,
                              decorationColor: Colors.red.shade300,
                            ),
                          ),
                        ),
                        if (optPrice > 0)
                          Text(
                            'S/. ${optPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: subColor,
                              decoration: textDecor,
                              decorationColor: Colors.red.shade300,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }
}
