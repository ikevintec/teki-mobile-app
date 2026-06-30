import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/providers/accounts_receivable/accounts_receivable_notifier.dart';
import 'package:teki_app/src/utils/contstants.dart';

class DateFiltersModal extends ConsumerStatefulWidget {
  final String tipoCuenta;

  const DateFiltersModal({super.key, required this.tipoCuenta});

  @override
  ConsumerState<DateFiltersModal> createState() => _DateFiltersModalState();
}

class _DateFiltersModalState extends ConsumerState<DateFiltersModal> {
  static const _format = 'dd-MM-yyyy';

  DateTimeRange? _emisionRange;
  DateTimeRange? _vencimientoRange;

  DateTime? _parse(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateFormat(_format).parse(value);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    final state = ref.read(accountsReceivableProvider(widget.tipoCuenta));
    final emisionDesde = _parse(state.filtroEmisionDesde);
    final emisionHasta = _parse(state.filtroEmisionHasta);
    final vencimientoDesde = _parse(state.filtroVencimientoDesde);
    final vencimientoHasta = _parse(state.filtroVencimientoHasta);

    if (emisionDesde != null && emisionHasta != null) {
      _emisionRange = DateTimeRange(start: emisionDesde, end: emisionHasta);
    }
    if (vencimientoDesde != null && vencimientoHasta != null) {
      _vencimientoRange =
          DateTimeRange(start: vencimientoDesde, end: vencimientoHasta);
    }
  }

  Future<void> _pickRange(DateTimeRange? current, ValueChanged<DateTimeRange> onPicked) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: current,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('es'),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
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

  String _label(DateTimeRange? range) {
    if (range == null) return 'Seleccionar rango';
    final fmt = DateFormat('dd MMM yyyy', 'es');
    return '${fmt.format(range.start)} - ${fmt.format(range.end)}';
  }

  Widget _buildRangeField({
    required String label,
    required DateTimeRange? range,
    required VoidCallback onTap,
    required VoidCallback? onClear,
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
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE2E4E7)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _label(range),
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: range == null ? Colors.grey : Colors.black87,
                    ),
                  ),
                ),
                if (range != null && onClear != null)
                  GestureDetector(
                    onTap: onClear,
                    child: const Icon(Icons.close, size: 18, color: Colors.grey),
                  ),
                const SizedBox(width: 6),
                const Icon(Icons.calendar_month, color: ColorSchema.primaryColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _apply() {
    final fmt = DateFormat(_format);
    ref.read(accountsReceivableProvider(widget.tipoCuenta).notifier).applyDateFilters(
          filtroEmisionDesde:
              _emisionRange != null ? fmt.format(_emisionRange!.start) : null,
          filtroEmisionHasta:
              _emisionRange != null ? fmt.format(_emisionRange!.end) : null,
          filtroVencimientoDesde: _vencimientoRange != null
              ? fmt.format(_vencimientoRange!.start)
              : null,
          filtroVencimientoHasta: _vencimientoRange != null
              ? fmt.format(_vencimientoRange!.end)
              : null,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRangeField(
          label: 'Fecha de emisión',
          range: _emisionRange,
          onTap: () => _pickRange(_emisionRange, (r) => setState(() => _emisionRange = r)),
          onClear: () => setState(() => _emisionRange = null),
        ),
        const SizedBox(height: 20),
        _buildRangeField(
          label: 'Fecha de vencimiento',
          range: _vencimientoRange,
          onTap: () => _pickRange(
              _vencimientoRange, (r) => setState(() => _vencimientoRange = r)),
          onClear: () => setState(() => _vencimientoRange = null),
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
}
