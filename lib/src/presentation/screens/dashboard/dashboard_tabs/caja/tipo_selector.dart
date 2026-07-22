import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Selector Ingresos / Egresos
// ─────────────────────────────────────────────────────────────────────────────

class TipoSelector extends StatelessWidget {
  final String tipo;
  final bool isBlocked;
  final ValueChanged<String> onChanged;

  const TipoSelector({
    super.key,
    required this.tipo,
    required this.isBlocked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _TipoBtn(
            label: 'Ingresos',
            isSelected: tipo == 'INGRESO',
            isBlocked: isBlocked && tipo != 'INGRESO',
            selectedColor: const Color(0xFF16A34A),
            onTap: () => onChanged('INGRESO'),
          ),
          _TipoBtn(
            label: 'Egresos',
            isSelected: tipo == 'EGRESO',
            isBlocked: isBlocked && tipo != 'EGRESO',
            selectedColor: const Color(0xFFDC2626),
            onTap: () => onChanged('EGRESO'),
          ),
        ],
      ),
    );
  }
}

class _TipoBtn extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isBlocked;
  final Color selectedColor;
  final VoidCallback onTap;

  const _TipoBtn({
    required this.label,
    required this.isSelected,
    required this.isBlocked,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: isBlocked ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 13,
              fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? selectedColor
                  : (isBlocked
                      ? Colors.grey.shade300
                      : Colors.grey.shade500),
            ),
          ),
        ),
      ),
    );
  }
}
