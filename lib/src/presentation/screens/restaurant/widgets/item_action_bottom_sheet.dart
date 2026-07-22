import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail.dart';
import 'package:teki_app/src/presentation/screens/restaurant/widgets/comanda_detail_item_tile.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/constants.dart';

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
    void Function(String? motivo)? onAnular,
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

class _ItemActionSheetContent extends ConsumerStatefulWidget {
  final CommandDetail item;
  final String status;
  final VoidCallback? onServir;
  final void Function(String? motivo)? onAnular;

  const _ItemActionSheetContent({
    required this.item,
    required this.status,
    this.onServir,
    this.onAnular,
  });

  @override
  ConsumerState<_ItemActionSheetContent> createState() => _ItemActionSheetContentState();
}

class _ItemActionSheetContentState extends ConsumerState<_ItemActionSheetContent> {
  Future<void> _handleAnular() async {
    final requiresMotivo = ref.read(sesionProvider).config?.motivoAnulacionPlato == true;

    if (!requiresMotivo) {
      Navigator.of(context).pop();
      widget.onAnular?.call(null);
      return;
    }

    final motivo = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _MotivoAnulacionDialog(),
    );

    if (motivo == null) return;

    if (mounted) Navigator.of(context).pop();
    widget.onAnular?.call(motivo);
  }

  @override
  Widget build(BuildContext context) {
    final upperStatus = widget.status.toUpperCase();
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
                          widget.item.producto?.nombre ?? '-',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(widget.item.cantidad ?? 1).toInt()}x  ·  S/. ${((widget.item.precioVenta ?? 0) * (widget.item.cantidad ?? 1)).toStringAsFixed(2)}',
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
                  widget.onServir?.call();
                },
              ),

            // ── Anular item ──────────────────────────────────────────────
            _ActionTile(
              icon: Icons.cancel_outlined,
              label: 'Anular item',
              color: const Color(0xFFE53935),
              onTap: _handleAnular,
            ),

            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// ─── Motivo anulacion dialog ──────────────────────────────────────────────────

class _MotivoAnulacionDialog extends StatefulWidget {
  const _MotivoAnulacionDialog();

  @override
  State<_MotivoAnulacionDialog> createState() => _MotivoAnulacionDialogState();
}

class _MotivoAnulacionDialogState extends State<_MotivoAnulacionDialog> {
  final _controller = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirmar() {
    setState(() => _submitted = true);
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = _submitted && _controller.text.trim().isEmpty;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: const BoxDecoration(
              color: Color(0xFFE53935),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cancel_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Motivo de anulación',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Motivo',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 13),
                  onChanged: (_) {
                    if (_submitted) setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Ingrese el motivo de anulación',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    errorText: isEmpty ? 'El motivo es requerido' : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: ColorSchema.primaryColor),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE53935)),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE53935)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
              ],
            ),
          ),
          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirmar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('Anular', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
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
