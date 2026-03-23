import 'package:flutter/material.dart';
import 'package:teki_app/src/data/models/teki_model/commandDetail.dart';
import 'package:teki_app/src/data/models/teki_model/commandDetailGroupOption.dart';
import 'package:teki_app/src/presentation/screens/restaurant/widgets/item_action_bottom_sheet.dart';

// ─── Status constants ────────────────────────────────────────────────────────

class ComandaDetailStatus {
  static const String pendiente = 'PENDIENTE';
  static const String preparado = 'PREPARADO';
  static const String cancelado = 'CANCELADO';
  static const String despachado = 'DESPACHADO';

  static bool isCancelledItem(CommandDetail item) =>
      item.eliminado == true ||
      item.estadoComandaDetalle?.toUpperCase() == cancelado;
}

// ─── Status style helpers ─────────────────────────────────────────────────────

Color statusBgColor(String? status) {
  switch (status?.toUpperCase()) {
    case ComandaDetailStatus.preparado:
      return const Color(0xFFFFFDE7);
    case ComandaDetailStatus.cancelado:
      return const Color(0xFFFFF5F5);
    case ComandaDetailStatus.despachado:
      return const Color(0xFFE3F2FD);
    default:
      return Colors.white;
  }
}

Color statusBorderColor(String? status) {
  switch (status?.toUpperCase()) {
    case ComandaDetailStatus.preparado:
      return const Color(0xFFF9A825);
    case ComandaDetailStatus.cancelado:
      return const Color(0xFFE53935);
    case ComandaDetailStatus.despachado:
      return const Color(0xFF1E88E5);
    default:
      return const Color(0xFFE0E0E0);
  }
}

// ─── ComandaDetailItemTile ────────────────────────────────────────────────────

/// Tile that renders a [CommandDetail] with status-based colours, optional
/// comanda badge, sub-items from [grupoProductoOpciones], and an interactive
/// bottom-sheet when [interactive] is true.
class ComandaDetailItemTile extends StatelessWidget {
  final CommandDetail item;

  /// Shows a purple "Comanda #N" badge on the tile.
  final int? numeroComanda;
  final bool showComandaBadge;

  /// When true, tapping the tile (for non-cancelled items) opens the action sheet.
  final bool interactive;

  /// Called when the user confirms "Servir" for this item.
  final VoidCallback? onServir;

  /// Called when the user confirms "Anular" for this item.
  final VoidCallback? onAnular;

  const ComandaDetailItemTile({
    super.key,
    required this.item,
    this.numeroComanda,
    this.showComandaBadge = false,
    this.interactive = true,
    this.onServir,
    this.onAnular,
  });

  bool get _isCancelled => ComandaDetailStatus.isCancelledItem(item);

  String get _resolvedStatus =>
      item.estadoComandaDetalle?.toUpperCase() ??
      ComandaDetailStatus.pendiente;

  @override
  Widget build(BuildContext context) {
    final isCancelled = _isCancelled;
    final status = _resolvedStatus;
    final bgColor = statusBgColor(status);
    final borderColor = statusBorderColor(status);
    final textDecor =
        isCancelled ? TextDecoration.lineThrough : TextDecoration.none;
    final textColor = isCancelled ? Colors.red.shade400 : Colors.black87;
    final total = (item.precioVenta ?? 0) * (item.cantidad ?? 1);
    final grupoOpciones =
        (item.grupoProductoOpciones ?? []).where((o) => o.eliminado != true).toList();

    final isPagado = item.cuenta?.pagado == true;

    return GestureDetector(
      onTap: (interactive && !isCancelled && !isPagado)
          ? () => ItemActionBottomSheet.show(
                context,
                item: item,
                status: status,
                onServir: onServir,
                onAnular: onAnular,
              )
          : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Main tile ──────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(12, 14, 12, 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: isCancelled ? 1.5 : 1.0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 68, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Main row ──────────────────────────────────────────
                  Row(
                    children: [
                      _QuantityBadge(
                        cantidad: item.cantidad ?? 1,
                        borderColor: borderColor,
                        isCancelled: isCancelled,
                        textDecor: textDecor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.producto?.nombre ?? '-',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            decoration: textDecor,
                            decorationColor: Colors.red.shade400,
                            decorationThickness: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // ── Price ─────────────────────────────────────────────
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'S/. ${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isCancelled ? Colors.red.shade400 : Colors.black54,
                          decoration: textDecor,
                          decorationColor: Colors.red.shade400,
                        ),
                      ),
                      if (!isCancelled) ...[
                        const SizedBox(width: 8),
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
                    ],
                  ),
                  // ── Group options sub-items ────────────────────────────
                  if (grupoOpciones.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    ...grupoOpciones.map(
                      (o) => _GroupOptionRow(
                        option: o,
                        isCancelled: isCancelled,
                        textDecor: textDecor,
                      ),
                    ),
                  ],
                  // ── Comanda badge (bottom-left, only when shown) ───────
                  if (showComandaBadge && numeroComanda != null) ...[
                    const SizedBox(height: 6),
                    _ComandaBadge(numeroComanda: numeroComanda!),
                  ],
                ],
              ),
            ),
          ),
          // ── Status badge — centered on the top border ─────────────────
          Positioned(
            top: 6,
            right: 20,
            child: ComandaStatusBadge(status: status),
          ),
        ],
      ),
    );
  }
}

// ─── Quantity badge ───────────────────────────────────────────────────────────

class _QuantityBadge extends StatelessWidget {
  final double cantidad;
  final Color borderColor;
  final bool isCancelled;
  final TextDecoration textDecor;

  const _QuantityBadge({
    required this.cantidad,
    required this.borderColor,
    required this.isCancelled,
    required this.textDecor,
  });

  @override
  Widget build(BuildContext context) {
    final label = cantidad == cantidad.truncateToDouble()
        ? '${cantidad.toInt()}x'
        : '${cantidad.toStringAsFixed(1)}x';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: borderColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isCancelled ? Colors.red.shade600 : Colors.grey.shade700,
          decoration: textDecor,
          decorationColor: Colors.red.shade400,
        ),
      ),
    );
  }
}

// ─── Group option sub-row ─────────────────────────────────────────────────────

class _GroupOptionRow extends StatelessWidget {
  final CommandDetailGroupOption option;
  final bool isCancelled;
  final TextDecoration textDecor;

  const _GroupOptionRow({
    required this.option,
    required this.isCancelled,
    required this.textDecor,
  });

  @override
  Widget build(BuildContext context) {
    final optPrice = (option.precio ?? 0) * (option.cantidad ?? 1);
    final subColor =
        isCancelled ? Colors.red.shade300 : Colors.grey.shade600;
    final name = option.nombreOpcion ?? option.nombreGrupo ?? '-';
    final qty = (option.cantidad ?? 1).toInt();

    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 2),
      child: Row(
        children: [
          Icon(Icons.subdirectory_arrow_right_rounded,
              size: 12, color: Colors.grey.shade400),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '${qty}x $name',
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
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class ComandaStatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const ComandaStatusBadge({super.key, required this.status, this.fontSize = 10});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    final IconData icon;

    switch (status.toUpperCase()) {
      case ComandaDetailStatus.preparado:
        color = const Color(0xFFF9A825);
        label = 'Preparado';
        icon = Icons.check_circle_outline_rounded;
        break;
      case ComandaDetailStatus.cancelado:
        color = const Color(0xFFE53935);
        label = 'Cancelado';
        icon = Icons.cancel_outlined;
        break;
      case ComandaDetailStatus.despachado:
        color = const Color(0xFF1E88E5);
        label = 'Despachado';
        icon = Icons.local_shipping_outlined;
        break;
      default:
        color = Colors.grey.shade500;
        label = 'Pendiente';
        icon = Icons.hourglass_empty_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Comanda number badge ─────────────────────────────────────────────────────

class _ComandaBadge extends StatelessWidget {
  final int numeroComanda;

  const _ComandaBadge({required this.numeroComanda});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200, width: 0.8),
      ),
      child: Text(
        'Comanda #$numeroComanda',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.purple.shade600,
        ),
      ),
    );
  }
}
