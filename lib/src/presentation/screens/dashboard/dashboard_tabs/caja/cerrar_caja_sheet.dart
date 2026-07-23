import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/providers/cash_register/cash_register_provider.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Arqueo y cierre de caja: por cada moneda muestra el efectivo esperado,
// pide el monto real contado y calcula la diferencia en vivo.
// ─────────────────────────────────────────────────────────────────────────────

/// Devuelve true si la caja se cerró.
Future<bool> showCerrarCajaSheet(
  BuildContext context, {
  required DateTime fecha,
}) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CerrarCajaSheet(fecha: fecha),
  );
  return ok ?? false;
}

class CerrarCajaSheet extends ConsumerStatefulWidget {
  final DateTime fecha;

  const CerrarCajaSheet({super.key, required this.fecha});

  @override
  ConsumerState<CerrarCajaSheet> createState() => _CerrarCajaSheetState();
}

class _CerrarCajaSheetState extends ConsumerState<CerrarCajaSheet> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final cajaState = ref.read(cashRegisterProvider);
    for (final moneda in cajaState.monedas) {
      _controllers[moneda] = TextEditingController();
    }
    if (_controllers.isEmpty) {
      _controllers['PEN'] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double _real(String moneda) =>
      double.tryParse(_controllers[moneda]?.text.trim() ?? '') ?? 0.0;

  String _fmt(String moneda, double v) =>
      '${formatExchange(moneda: moneda)}${v.toStringAsFixed(2)}';

  Future<void> _confirmarYCerrar() async {
    final cajaState = ref.read(cashRegisterProvider);
    final esperado = cajaState.totalEfectivoPorMoneda;

    final resumenDiferencias = _controllers.keys.map((moneda) {
      final diff = _real(moneda) - (esperado[moneda] ?? 0.0);
      if (diff == 0) return '$moneda cuadrada';
      return diff > 0
          ? '$moneda con sobrante de ${_fmt(moneda, diff)}'
          : '$moneda con faltante de ${_fmt(moneda, diff.abs())}';
    }).join(', ');

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar caja',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: Text(
          'Vas a cerrar la caja del '
          '${DateFormat('dd/MM/yyyy').format(widget.fecha)}: '
          '$resumenDiferencias. Esta acción registra el arqueo.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar caja'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    setState(() => _isSubmitting = true);
    final montosReales = {
      for (final moneda in _controllers.keys) moneda: _real(moneda),
    };
    final ok = await ref
        .read(cashRegisterProvider.notifier)
        .cerrarCaja(montosReales: montosReales, fecha: widget.fecha);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cajaState = ref.watch(cashRegisterProvider);
    final esperado = cajaState.totalEfectivoPorMoneda;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lock_outline_rounded,
                      color: Color(0xFFDC2626), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cerrar caja',
                          style: GoogleFonts.roboto(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        'Cuenta el efectivo e ingresa el monto real por moneda',
                        style: GoogleFonts.roboto(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final moneda in _controllers.keys) ...[
              _monedaArqueo(moneda, esperado[moneda] ?? 0.0),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _confirmarYCerrar,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_outline_rounded, size: 18),
                label: const Text('Cerrar caja'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFFDC2626).withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: GoogleFonts.roboto(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _monedaArqueo(String moneda, double esperadoMoneda) {
    final real = _real(moneda);
    final diff = real - esperadoMoneda;
    final tieneInput = _controllers[moneda]!.text.trim().isNotEmpty;

    final Color diffColor;
    final String diffLabel;
    if (!tieneInput) {
      diffColor = Colors.grey.shade400;
      diffLabel = 'Ingresa el monto contado';
    } else if (diff == 0) {
      diffColor = const Color(0xFF16A34A);
      diffLabel = 'Cuadrado';
    } else if (diff > 0) {
      diffColor = const Color(0xFFE65100);
      diffLabel = 'Sobrante: ${_fmt(moneda, diff)}';
    } else {
      diffColor = const Color(0xFFDC2626);
      diffLabel = 'Faltante: ${_fmt(moneda, diff.abs())}';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(moneda,
                  style: GoogleFonts.roboto(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(
                'Efectivo esperado: ${_fmt(moneda, esperadoMoneda)}',
                style: GoogleFonts.roboto(
                    fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controllers[moneda],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.roboto(
                fontSize: 15, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: '0.00',
              prefixText: formatExchange(moneda: moneda),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: ColorSchema.primaryColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                !tieneInput
                    ? Icons.edit_outlined
                    : (diff == 0
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded),
                size: 14,
                color: diffColor,
              ),
              const SizedBox(width: 6),
              Text(diffLabel,
                  style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: diffColor)),
            ],
          ),
        ],
      ),
    );
  }
}
