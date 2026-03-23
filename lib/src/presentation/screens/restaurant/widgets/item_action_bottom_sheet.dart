import 'package:flutter/material.dart';
import 'package:teki_app/src/data/models/teki_model/commandDetail.dart';
import 'package:teki_app/src/presentation/screens/restaurant/widgets/comanda_detail_item_tile.dart';

/// Shows a bottom sheet with available actions for a [CommandDetail] item
/// based on its [status].
///
/// Actions per status:
/// - PENDIENTE  → Anular item
/// - PREPARADO  → Servir, Anular item
/// - DESPACHADO → Anular item
/// - CANCELADO  → (no sheet shown — caller should guard this)
class ItemActionBottomSheet {
  static Future<void> show(
    BuildContext context, {
    required CommandDetail item,
    required String status,
    VoidCallback? onServir,
    VoidCallback? onAnular,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ItemActionSheetContent(
        item: item,
        status: status,
        onServir: onServir,
        onAnular: onAnular,
      ),
    );
  }
}

class _ItemActionSheetContent extends StatelessWidget {
  final CommandDetail item;
  final String status;
  final VoidCallback? onServir;
  final VoidCallback? onAnular;

  const _ItemActionSheetContent({
    required this.item,
    required this.status,
    this.onServir,
    this.onAnular,
  });

  @override
  Widget build(BuildContext context) {
    final upperStatus = status.toUpperCase();
    final showServir = upperStatus == ComandaDetailStatus.preparado;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle ────────────────────────────────────────────────────
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Item summary header ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.producto?.nombre ?? '-',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(item.cantidad ?? 1).toInt()}x  ·  S/. ${((item.precioVenta ?? 0) * (item.cantidad ?? 1)).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ComandaStatusBadge(status: upperStatus),
                ],
              ),
            ),

            const SizedBox(height: 10),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 4),

            // ── Servir (PREPARADO only) ───────────────────────────────────
            if (showServir)
              _ActionTile(
                icon: Icons.room_service_rounded,
                label: 'Servir',
                color: const Color(0xFF1E88E5),
                onTap: () {
                  Navigator.of(context).pop();
                  onServir?.call();
                },
              ),

            // ── Anular item ──────────────────────────────────────────────
            _ActionTile(
              icon: Icons.cancel_outlined,
              label: 'Anular item',
              color: const Color(0xFFE53935),
              onTap: () {
                Navigator.of(context).pop();
                onAnular?.call();
              },
            ),

            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// ─── Action tile ──────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
