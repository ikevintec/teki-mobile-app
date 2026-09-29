import 'package:flutter/material.dart';

/// Estilo visual de una acción de pedido online.
enum OrderActionKind { primary, danger, ghost, brand }

class _ActionPalette {
  final Color bg;
  final Color fg;
  final Color border;
  const _ActionPalette(this.bg, this.fg, this.border);
}

/// Botón de acción minimalista y consistente usado en la lista de pedidos
/// online y en el detalle. Soporta variante con o sin texto y estado de carga.
class OrderActionButton extends StatelessWidget {
  final String? label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;
  final OrderActionKind kind;

  const OrderActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.label,
    this.loading = false,
    this.kind = OrderActionKind.ghost,
  });

  _ActionPalette get _palette => switch (kind) {
    OrderActionKind.primary => const _ActionPalette(
      Color(0x1F16A34A),
      Color(0xFF16A34A),
      Colors.transparent,
    ),
    OrderActionKind.danger => const _ActionPalette(
      Color(0x1FDC2626),
      Color(0xFFDC2626),
      Colors.transparent,
    ),
    OrderActionKind.ghost => const _ActionPalette(
      Color(0xFFF3F5F9),
      Color(0xFF334155),
      Colors.transparent,
    ),
    OrderActionKind.brand => const _ActionPalette(
      Color(0x1F2C6AE5),
      Color(0xFF2C6AE5),
      Colors.transparent,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final palette = _palette;
    final disabled = onTap == null || loading;

    final content = loading
        ? SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: palette.fg,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: palette.fg),
              if (label != null) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: palette.fg,
                    ),
                  ),
                ),
              ],
            ],
          );

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Material(
        color: palette.bg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 36,
            padding: EdgeInsets.symmetric(horizontal: label == null ? 10 : 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: palette.border),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
