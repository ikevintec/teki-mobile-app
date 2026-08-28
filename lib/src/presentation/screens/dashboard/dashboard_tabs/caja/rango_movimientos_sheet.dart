import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/caja/historial_item.dart';
import 'package:teki_app/src/providers/cash_register/caja_resumen_provider.dart';
import 'package:teki_app/src/utils/constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Drill-down del modo reporte: movimientos del rango con scroll infinito
// y filtro por tipo (Todos / Ingresos / Egresos).
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showRangoMovimientosSheet(
  BuildContext context, {
  required DateTimeRange range,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => RangoMovimientosSheet(range: range),
  );
}

class RangoMovimientosSheet extends ConsumerStatefulWidget {
  final DateTimeRange range;

  const RangoMovimientosSheet({super.key, required this.range});

  @override
  ConsumerState<RangoMovimientosSheet> createState() =>
      _RangoMovimientosSheetState();
}

class _RangoMovimientosSheetState extends ConsumerState<RangoMovimientosSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rangoMovimientosProvider.notifier).load(widget.range);
    });
  }

  void _onFiltroChanged(String? tipo) {
    ref.read(rangoMovimientosProvider.notifier).load(widget.range, tipo: tipo);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rangoMovimientosProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF7F7F9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Movimientos del periodo',
                      style: GoogleFonts.roboto(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _formatRange(widget.range),
                            style: GoogleFonts.roboto(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _filtroChip('Todos', null, state.tipo),
                        const SizedBox(width: 6),
                        _filtroChip('Ingresos', 'INGRESO', state.tipo),
                        const SizedBox(width: 6),
                        _filtroChip('Egresos', 'EGRESO', state.tipo),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Divider(height: 1, color: Colors.grey.shade200),
              Expanded(
                child: _buildList(state, scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Rango legible: un solo día -> "27 ago 2026"; rango -> "20 ago – 27 ago 2026"
  /// (omite el año en el inicio si ambos extremos comparten año).
  String _formatRange(DateTimeRange range) {
    final ini = range.start;
    final fin = range.end;
    final mismoDia =
        ini.year == fin.year && ini.month == fin.month && ini.day == fin.day;
    if (mismoDia) {
      return DateFormat("d MMM y", 'es').format(ini);
    }
    final iniFmt = ini.year == fin.year
        ? DateFormat('d MMM', 'es').format(ini)
        : DateFormat('d MMM y', 'es').format(ini);
    final finFmt = DateFormat('d MMM y', 'es').format(fin);
    return '$iniFmt – $finFmt';
  }

  Widget _filtroChip(String label, String? tipo, String? actual) {
    final selected = actual == tipo;
    return GestureDetector(
      onTap: () => _onFiltroChanged(tipo),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? ColorSchema.primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildList(RangoMovimientosState state, ScrollController controller) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
            color: ColorSchema.primaryColor, strokeWidth: 2),
      );
    }
    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Text('No se pudieron cargar los movimientos',
            style: GoogleFonts.roboto(
                fontSize: 13, color: Colors.grey.shade500)),
      );
    }
    if (state.items.isEmpty) {
      return Center(
        child: Text('Sin movimientos',
            style: GoogleFonts.roboto(
                fontSize: 13, color: Colors.grey.shade400)),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
          ref.read(rangoMovimientosProvider.notifier).loadMore();
        }
        return false;
      },
      child: ListView.builder(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                    color: ColorSchema.primaryColor, strokeWidth: 2),
              ),
            );
          }
          final item = state.items[index];
          return HistorialItem(
            item: item,
            tipo: item.tipoMovimientoCaja ?? 'INGRESO',
          );
        },
      ),
    );
  }
}
