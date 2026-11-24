import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/providers/cash_register/cash_register_provider.dart';
import 'package:teki_app/src/providers/cash_register/currencies_provider.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Apertura de caja: monto inicial de efectivo por moneda para la fecha
// seleccionada. Mismo payload que la web (detalles APERTURA_CAJA).
// ─────────────────────────────────────────────────────────────────────────────

/// Devuelve true si la caja se aperturó.
Future<bool> showAperturarCajaSheet(
  BuildContext context, {
  required DateTime fecha,
}) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AperturarCajaSheet(fecha: fecha),
  );
  return ok ?? false;
}

class AperturarCajaSheet extends ConsumerStatefulWidget {
  final DateTime fecha;

  const AperturarCajaSheet({super.key, required this.fecha});

  @override
  ConsumerState<AperturarCajaSheet> createState() =>
      _AperturarCajaSheetState();
}

class _AperturarCajaSheetState extends ConsumerState<AperturarCajaSheet> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currenciesProvider.notifier).ensureLoaded();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerDe(String moneda) =>
      _controllers.putIfAbsent(moneda, TextEditingController.new);

  Future<void> _aperturar() async {
    setState(() => _isSubmitting = true);
    final montos = {
      for (final e in _controllers.entries)
        e.key: double.tryParse(e.value.text.trim()) ?? 0.0,
    };
    if (montos.isEmpty) montos['PEN'] = 0.0;

    final ok = await ref.read(cashRegisterProvider.notifier).aperturarCaja(
          fecha: widget.fecha,
          montosIniciales: montos,
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currenciesState = ref.watch(currenciesProvider);
    final monedas = currenciesState.currencies
        .map((c) => c.codigoMoneda)
        .whereType<String>()
        .toList();
    if (monedas.isEmpty) monedas.add('PEN');

    final fechaLabel = DateFormat("dd 'de' MMMM", 'es').format(widget.fecha);

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
                    color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lock_open_rounded,
                      color: Color(0xFF16A34A), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Aperturar caja',
                          style: GoogleFonts.roboto(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        'Caja del $fechaLabel · efectivo inicial por moneda',
                        style: GoogleFonts.roboto(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (currenciesState.isLoading && monedas.length == 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(
                      color: ColorSchema.primaryColor, strokeWidth: 2),
                ),
              )
            else
              for (final moneda in monedas) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: _controllerDe(moneda),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.roboto(
                        fontSize: 15, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: 'Monto inicial ($moneda)',
                      hintText: '0.00',
                      prefixText: formatExchange(moneda: moneda),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
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
                ),
              ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _aperturar,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_open_rounded, size: 18),
                label: const Text('Aperturar caja'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFF16A34A).withValues(alpha: 0.5),
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
}
