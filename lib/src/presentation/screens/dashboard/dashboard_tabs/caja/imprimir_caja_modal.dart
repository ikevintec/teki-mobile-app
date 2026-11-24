import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:teki_app/src/utils/constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Modal de impresión de reporte de caja
// ─────────────────────────────────────────────────────────────────────────────

class ImprimirCajaModal extends StatefulWidget {
  final int idCaja;
  final String moneda;

  const ImprimirCajaModal({super.key, required this.idCaja, required this.moneda});

  @override
  State<ImprimirCajaModal> createState() => _ImprimirCajaModalState();
}

class _ImprimirCajaModalState extends State<ImprimirCajaModal> {
  String _tipoImpresion = 'TICKET';
  bool _detallado = false;

  Future<void> _imprimir() async {
    final tipo = _tipoImpresion == 'TICKET' ? 'REPORTE_CAJA_TICKET' : 'REPORTE_CAJA';
    final baseUrl = Environment.apiUrl;
    final url = '$baseUrl/public/pdf/cash-register/${widget.idCaja}?moneda=${widget.moneda}&tipo=$tipo&detalle=$_detallado';
    final uri = Uri.parse(url);
    Navigator.of(context).pop();
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Imprimir reporte',
              style: GoogleFonts.roboto(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F1F1F),
              ),
            ),
            const SizedBox(height: 16),
            // Fila 1: tipo de impresión
            Text(
              'Tipo de impresión',
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 6),
            _SegmentSelector(
              options: const ['TICKET', 'A4'],
              selected: _tipoImpresion,
              onChanged: (v) => setState(() => _tipoImpresion = v),
            ),
            const SizedBox(height: 14),
            // Fila 2: detalle
            Text(
              'Detalle',
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 6),
            _SegmentSelector(
              options: const ['SIMPLE', 'DETALLADO'],
              selected: _detallado ? 'DETALLADO' : 'SIMPLE',
              onChanged: (v) => setState(() => _detallado = v == 'DETALLADO'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _imprimir,
                icon: const Icon(Icons.print_rounded, size: 16),
                label: const Text('Imprimir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorSchema.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentSelector extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const _SegmentSelector({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = opt == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
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
                  opt,
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? ColorSchema.primaryColor
                        : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
