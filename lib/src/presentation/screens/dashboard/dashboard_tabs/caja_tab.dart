import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/cashRegisterDetail.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/widgets/calendar_filter.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/caja_balance_screen.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/caja_movimiento_screen.dart';
import 'package:teki_app/src/providers/cash_register/cash_register_detail_provider.dart';
import 'package:teki_app/src/providers/cash_register/cash_register_provider.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/formats.dart';

class CajaTab extends ConsumerStatefulWidget {
  final ValueNotifier<int> refreshNotifier;

  const CajaTab({super.key, required this.refreshNotifier});

  @override
  ConsumerState<CajaTab> createState() => _CajaTabState();
}

class _CajaTabState extends ConsumerState<CajaTab> {
  String? _selectedMoneda;
  DateTime _selectedDate = DateTime.now();
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    widget.refreshNotifier.addListener(_onRefresh);
    // La carga inicial la dispara CustomDatePicker vía onDateSelected al montarse.
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    widget.refreshNotifier.removeListener(_onRefresh);
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(cashRegisterDetailProvider.notifier).loadMore();
    }
  }

  /// Llamado por refreshNotifier (al volver de una sub-pantalla).
  /// Refresca la fecha actualmente seleccionada.
  void _onRefresh() {
    setState(() => _selectedMoneda = null);
    _fetchCashRegister();
  }

  /// Llamado por CustomDatePicker cada vez que el usuario selecciona una fecha.
  void _onDateChanged(DateTimeRange range) {
    setState(() {
      _selectedDate = range.start;
      _selectedMoneda = null;
    });
    _fetchCashRegister();
  }

  Future<void> _fetchCashRegister() async {
    if (!mounted) return;
    final sesion = ref.read(sesionProvider);
    final idPV = sesion.office?.id ?? 0;
    final idEV = sesion.saleStation?.id ?? 0;
    final fechaStr = DateFormat('dd-MM-yyyy').format(_selectedDate);
    await ref.read(cashRegisterProvider.notifier).fetch(
          idPuntoVenta: idPV,
          idEstacionVenta: idEV,
          fecha: fechaStr,
        );
    if (!mounted) return;
    // justo después
    final cajaState = ref.read(cashRegisterProvider);
    if (cajaState.registers.isEmpty) {
      ref.read(cashRegisterDetailProvider.notifier).clear();
    } else {
      _loadDetail();
    }
  }
  /// Calcula la moneda activa con la misma lógica que el build y dispara
  /// la carga del historial usando el primer registro disponible.
  void _loadDetail() {
    final cajaState = ref.read(cashRegisterProvider);
    if (cajaState.registers.isEmpty) return;
    final idCaja = cajaState.registers.first.id;
    if (idCaja == null) return;

    final monedas = {...cajaState.balancePorMoneda.keys}.toList()
      ..sort((a, b) => a == 'PEN' ? -1 : 1);
    final moneda = (_selectedMoneda != null && monedas.contains(_selectedMoneda))
        ? _selectedMoneda!
        : (monedas.contains('PEN')
            ? 'PEN'
            : (monedas.isNotEmpty ? monedas.first : 'PEN'));

    ref.read(cashRegisterDetailProvider.notifier).load(
          idCaja: idCaja,
          moneda: moneda,
        );
  }

  void _onMonedaChanged(String newMoneda) {
    setState(() => _selectedMoneda = newMoneda);
    ref.read(cashRegisterDetailProvider.notifier).changeMoneda(newMoneda);
  }

  String _fmt(Map<String, double> map, String moneda) {
    final symbol = formatExchange(moneda: moneda);
    final v = map[moneda] ?? 0.0;
    return '$symbol${v.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final cajaState = ref.watch(cashRegisterProvider);
    final detailState = ref.watch(cashRegisterDetailProvider);

    final balance = cajaState.balancePorMoneda;
    final ingresos = cajaState.totalIngresosPorMoneda;
    final egresos = cajaState.totalEgresosPorMoneda;

    final monedas = {...balance.keys}.toList()
      ..sort((a, b) => a == 'PEN' ? -1 : 1);

    final monedaActiva =
        (_selectedMoneda != null && monedas.contains(_selectedMoneda))
            ? _selectedMoneda!
            : (monedas.contains('PEN')
                ? 'PEN'
                : (monedas.isNotEmpty ? monedas.first : 'PEN'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Selector de fecha ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(top: 0, left: 8, right: 4),
          child: CustomDatePicker(
            onDateSelected: _onDateChanged,
            singleDayPicker: true,
          ),
        ),
        SizedBox(height: 12),
        // ── Tarjeta de balance ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: cajaState.isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: ColorSchema.primaryColor,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : cajaState.error != null
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.grey.shade400, size: 44),
                            const SizedBox(height: 10),
                            Text(
                              'No se pudo cargar la caja',
                              style: GoogleFonts.roboto(
                                  fontSize: 14, color: Colors.grey.shade500),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            TextButton.icon(
                              onPressed: () {
                                setState(() => _selectedMoneda = null);
                                _fetchCashRegister();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                              style: TextButton.styleFrom(
                                  foregroundColor: ColorSchema.primaryColor),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: ColorSchema.primaryColor
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: ColorSchema.primaryColor,
                                    size: 21,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Balance',
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const Spacer(),
                                if (monedas.length > 1) ...[
                                  _CurrencySelector(
                                    monedas: monedas,
                                    value: monedaActiva,
                                    onChanged: _onMonedaChanged,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedMoneda = null);
                                    _fetchCashRegister();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: ColorSchema.primaryColor
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.refresh_rounded,
                                      size: 18,
                                      color: ColorSchema.primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                monedas.isEmpty
                                    ? '${formatExchange(moneda: 'PEN')}0.00'
                                    : _fmt(balance, monedaActiva),
                                style: GoogleFonts.roboto(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey.shade900,
                                ),
                              ),
                            ),
                            Divider(
                                height: 1,
                                color: Colors.grey.shade200),
                            const SizedBox(height: 12),
                            monedas.isEmpty
                                ? Center(
                                    child: Text(
                                      'Sin movimientos hoy',
                                      style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  )
                                : Row(
                                    children: [
                                      _MovimientoItem(
                                        label: 'Ingresos',
                                        value: _fmt(ingresos, monedaActiva),
                                        dotColor: const Color(0xFF22C55E),
                                        textColor: const Color(0xFF16A34A),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 52,
                                        color: Colors.grey.shade200,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                      ),
                                      _MovimientoItem(
                                        label: 'Egresos',
                                        value: _fmt(egresos, monedaActiva),
                                        dotColor: const Color(0xFFEF4444),
                                        textColor: const Color(0xFFDC2626),
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Botón ver balance ──────────────────────────────────────────────
        if (!cajaState.isLoading &&
            cajaState.registers.isNotEmpty &&
            cajaState.registers.first.id != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CajaBalanceScreen(
                      idCaja: cajaState.registers.first.id!,
                    ),
                  ),
                ),
                icon: const Icon(Icons.bar_chart_rounded, size: 17),
                label: const Text('Ver balance'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorSchema.primaryColor,
                  side: BorderSide(
                    color: ColorSchema.primaryColor.withValues(alpha: 0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ),

        const SizedBox(height: 12),

        // ── Selector Ingresos / Egresos ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _TipoSelector(
            tipo: detailState.tipo,
            isBlocked: detailState.isLoading || detailState.isLoadingMore,
            onChanged: (t) =>
                ref.read(cashRegisterDetailProvider.notifier).changeTipo(t),
          ),
        ),

        const SizedBox(height: 10),

        // ── Historial (solo esta parte scrollea) ───────────────────────────
        Expanded(
          child: _buildHistorialList(detailState, cajaState.isLoading),
        ),
      ],
    );
  }

  Widget _buildHistorialList(
      CashRegisterDetailState detailState, bool cajaLoading) {
    if (cajaLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: ColorSchema.primaryColor,
          strokeWidth: 2,
        ),
      );
    }

    if (detailState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: ColorSchema.primaryColor,
          strokeWidth: 2,
        ),
      );
    }

    if (detailState.error != null && detailState.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.grey.shade400, size: 40),
            const SizedBox(height: 8),
            Text(
              'No se pudo cargar el historial',
              style: GoogleFonts.roboto(
                  fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _loadDetail,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar'),
              style: TextButton.styleFrom(
                  foregroundColor: ColorSchema.primaryColor),
            ),
          ],
        ),
      );
    }

    if (detailState.items.isEmpty) {
      return Center(
        child: Text(
          'Sin movimientos',
          style: GoogleFonts.roboto(
              fontSize: 13, color: Colors.grey.shade400),
        ),
      );
    }

    return RefreshIndicator(
      color: ColorSchema.primaryColor,
      onRefresh: () async => _loadDetail(),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount:
            detailState.items.length + (detailState.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == detailState.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                  color: ColorSchema.primaryColor,
                  strokeWidth: 2,
                ),
              ),
            );
          }
          final item = detailState.items[index];
          return _HistorialItem(
            item: item,
            tipo: detailState.tipo,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Selector Ingresos / Egresos
// ─────────────────────────────────────────────────────────────────────────────

class _TipoSelector extends StatelessWidget {
  final String tipo;
  final bool isBlocked;
  final ValueChanged<String> onChanged;

  const _TipoSelector({
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

// ─────────────────────────────────────────────────────────────────────────────
// Item del historial
// ─────────────────────────────────────────────────────────────────────────────

class _HistorialItem extends StatelessWidget {
  final CashRegisterDetail item;
  final String tipo;

  const _HistorialItem({required this.item, required this.tipo});

  @override
  Widget build(BuildContext context) {
    final isIngreso = tipo == 'INGRESO';
    final amountColor =
        isIngreso ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final iconBgColor = isIngreso
        ? const Color(0xFF16A34A).withValues(alpha: 0.1)
        : const Color(0xFFDC2626).withValues(alpha: 0.1);
    final symbol = formatExchange(moneda: item.monedaMovimientoCaja ?? 'PEN');
    final monto = item.monto ?? 0.0;
    final hora = item.fechaMovimiento != null
        ? DateFormat('HH:mm', 'es').format(item.fechaMovimiento!)
        : '';
    final usuario = item.usuario?.nombreCompleto ?? '';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CajaMovimientoScreen(item: item),
        ),
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              isIngreso
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: amountColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Descripción + usuario
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.descripcion ?? item.conceptoMovimientoCaja ?? '-',
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F1F1F),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (usuario.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    usuario,
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Monto + hora
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$symbol${monto.toStringAsFixed(2)}',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: amountColor,
                ),
              ),
              if (hora.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 11, color: Colors.grey.shade400),
                    const SizedBox(width: 3),
                    Text(
                      hora,
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Selector de moneda (OverlayEntry — sin NavBar)
// ─────────────────────────────────────────────────────────────────────────────

class _MovimientoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color dotColor;
  final Color textColor;

  const _MovimientoItem({
    required this.label,
    required this.value,
    required this.dotColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: dotColor,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencySelector extends StatefulWidget {
  final List<String> monedas;
  final String value;
  final ValueChanged<String> onChanged;

  const _CurrencySelector({
    required this.monedas,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_CurrencySelector> createState() => _CurrencySelectorState();
}

class _CurrencySelectorState extends State<_CurrencySelector> {
  final _link = LayerLink();
  OverlayEntry? _entry;
  bool _open = false;

  void _toggle() => _open ? _close() : _show();

  void _show() {
    final overlay = Overlay.of(context);
    _entry = OverlayEntry(builder: (_) => _buildOverlay());
    overlay.insert(_entry!);
    setState(() => _open = true);
  }

  void _close() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() => _open = false);
  }

  void _select(String moneda) {
    _close();
    widget.onChanged(moneda);
  }

  Widget _buildOverlay() {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _close,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 6),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widget.monedas.map((m) {
                    final isSelected = m == widget.value;
                    return InkWell(
                      onTap: () => _select(m),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            if (isSelected)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(Icons.check_rounded,
                                    size: 13,
                                    color: ColorSchema.primaryColor),
                              ),
                            Text(
                              m,
                              style: GoogleFonts.roboto(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? ColorSchema.primaryColor
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        onTap: _toggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _open
                ? ColorSchema.primaryColor.withValues(alpha: 0.12)
                : ColorSchema.primaryColor.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ColorSchema.primaryColor.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.value,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ColorSchema.primaryColor,
                ),
              ),
              const SizedBox(width: 2),
              AnimatedRotation(
                turns: _open ? 0.5 : 0,
                duration: const Duration(milliseconds: 150),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 15,
                  color: ColorSchema.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
