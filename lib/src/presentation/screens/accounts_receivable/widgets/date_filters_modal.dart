import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/providers/accounts_receivable/accounts_receivable_notifier.dart';
import 'package:teki_app/src/utils/constants.dart';

class DateFiltersModal extends ConsumerStatefulWidget {
  final String tipoCuenta;

  const DateFiltersModal({super.key, required this.tipoCuenta});

  @override
  ConsumerState<DateFiltersModal> createState() => _DateFiltersModalState();
}

class _DateFiltersModalState extends ConsumerState<DateFiltersModal> {
  static const _format = 'dd-MM-yyyy';

  DateTime? _emisionDesde;
  DateTime? _emisionHasta;
  DateTime? _vencimientoDesde;
  DateTime? _vencimientoHasta;

  @override
  void initState() {
    super.initState();
    final state = ref.read(accountsReceivableProvider(widget.tipoCuenta));
    _emisionDesde = _parse(state.filtroEmisionDesde);
    _emisionHasta = _parse(state.filtroEmisionHasta);
    _vencimientoDesde = _parse(state.filtroVencimientoDesde);
    _vencimientoHasta = _parse(state.filtroVencimientoHasta);
  }

  DateTime? _parse(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateFormat(_format).parse(value);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pick({
    required DateTime? current,
    required ValueChanged<DateTime?> onPicked,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: firstDate ?? DateTime(now.year - 5),
      lastDate: lastDate ?? DateTime(now.year + 5),
      locale: const Locale('es'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ColorSchema.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) onPicked(picked);
  }

  void _apply() {
    final fmt = DateFormat(_format);
    ref.read(accountsReceivableProvider(widget.tipoCuenta).notifier).applyDateFilters(
          filtroEmisionDesde: _emisionDesde != null ? fmt.format(_emisionDesde!) : null,
          filtroEmisionHasta: _emisionHasta != null ? fmt.format(_emisionHasta!) : null,
          filtroVencimientoDesde:
              _vencimientoDesde != null ? fmt.format(_vencimientoDesde!) : null,
          filtroVencimientoHasta:
              _vencimientoHasta != null ? fmt.format(_vencimientoHasta!) : null,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateGroup(
          label: 'Fecha de emisión',
          desde: _emisionDesde,
          hasta: _emisionHasta,
          onDesdeChanged: (d) => setState(() => _emisionDesde = d),
          onHastaChanged: (d) => setState(() => _emisionHasta = d),
        ),
        const SizedBox(height: 20),
        _buildDateGroup(
          label: 'Fecha de vencimiento',
          desde: _vencimientoDesde,
          hasta: _vencimientoHasta,
          onDesdeChanged: (d) => setState(() => _vencimientoDesde = d),
          onHastaChanged: (d) => setState(() => _vencimientoHasta = d),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Volver',
                  style: GoogleFonts.roboto(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorSchema.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Aplicar',
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateGroup({
    required String label,
    required DateTime? desde,
    required DateTime? hasta,
    required ValueChanged<DateTime?> onDesdeChanged,
    required ValueChanged<DateTime?> onHastaChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.raleway(
            color: const Color(0xFF444444),
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _DateInput(
                hint: 'Desde',
                value: desde,
                onTap: () => _pick(
                  current: desde,
                  lastDate: hasta,
                  onPicked: onDesdeChanged,
                ),
                onClear: () => onDesdeChanged(null),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DateInput(
                hint: 'Hasta',
                value: hasta,
                onTap: () => _pick(
                  current: hasta,
                  firstDate: desde,
                  onPicked: onHastaChanged,
                ),
                onClear: () => onHastaChanged(null),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DateInput extends StatelessWidget {
  final String hint;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DateInput({
    required this.hint,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    final label = hasValue ? DateFormat('dd-MM-yyyy').format(value!) : hint;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: hasValue ? ColorSchema.primaryColor : const Color(0xFFE2E4E7),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 14,
              color: hasValue ? ColorSchema.primaryColor : Colors.grey,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                  color: hasValue ? Colors.black87 : Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasValue)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 14, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
