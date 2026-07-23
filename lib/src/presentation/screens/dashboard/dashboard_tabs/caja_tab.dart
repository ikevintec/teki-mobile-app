import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/widgets/calendar_filter.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/caja/currency_selector.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/caja/empty_caja_card.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/caja/historial_item.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/caja/aperturar_caja_sheet.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/caja/cerrar_caja_sheet.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/caja/open_register_banner.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/caja/rango_movimientos_sheet.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/caja/resumen_view.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/caja/imprimir_caja_modal.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/caja/movimiento_item.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/caja/tipo_selector.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/caja_balance_screen.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/widgets/cash_movement_sheet.dart';
import 'package:teki_app/src/providers/cash_register/caja_resumen_provider.dart';
import 'package:teki_app/src/providers/cash_register/cash_register_detail_provider.dart';
import 'package:teki_app/src/providers/cash_register/cash_register_provider.dart';
import 'package:teki_app/src/providers/cash_register/currencies_provider.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';
import 'package:teki_app/src/utils/notifications.dart';

class CajaTab extends ConsumerStatefulWidget {
  final ValueNotifier<int> refreshNotifier;

  const CajaTab({super.key, required this.refreshNotifier});

  @override
  ConsumerState<CajaTab> createState() => _CajaTabState();
}

class _CajaTabState extends ConsumerState<CajaTab> {
  String? _selectedMoneda;
  DateTime _selectedDate = DateTime.now();

  /// Rango seleccionado en el picker. Un solo día = modo operativo (caja);
  /// más de un día = modo reporte (resumen agregado).
  DateTimeRange? _selectedRange;
  late final ScrollController _scrollController;

  bool get _isDayMode {
    final r = _selectedRange;
    return r == null || r.start == r.end;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    widget.refreshNotifier.addListener(_onRefresh);
    // La carga inicial la dispara CustomDatePicker vía onDateSelected al montarse.
    // Precarga (una sola vez, no bloqueante) las monedas para el registro de
    // ingresos/egresos. Si falla, no afecta la vista de la caja.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currenciesProvider.notifier).ensureLoaded();
    });
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
  /// Refresca la selección actual (día o rango).
  void _onRefresh() {
    setState(() => _selectedMoneda = null);
    if (_isDayMode) {
      _fetchCashRegister();
    } else if (_selectedRange != null) {
      ref.read(cajaResumenProvider.notifier).fetch(_selectedRange!);
    }
  }

  /// Llamado por CustomDatePicker cada vez que el usuario selecciona
  /// una fecha o un rango.
  void _onDateChanged(DateTimeRange range) {
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    setState(() {
      _selectedRange = DateTimeRange(start: start, end: end);
      _selectedDate = start;
      _selectedMoneda = null;
    });
    if (_isDayMode) {
      _fetchCashRegister();
    } else {
      ref.read(cajaResumenProvider.notifier).fetch(_selectedRange!);
    }
  }

  Future<void> _fetchCashRegister() async {
    if (!mounted) return;
    await ref.read(cashRegisterProvider.notifier).fetchAndLoadDetail(
          selectedMoneda: _selectedMoneda,
          fecha: _selectedDate,
        );
  }

  void _loadDetail() {
    ref
        .read(cashRegisterProvider.notifier)
        .loadDetail(selectedMoneda: _selectedMoneda);
  }

  void _onMonedaChanged(String newMoneda) {
    setState(() => _selectedMoneda = newMoneda);
    ref.read(cashRegisterDetailProvider.notifier).changeMoneda(newMoneda);
  }

  /// Tap en "Aperturar caja": si hay una caja abierta de otra fecha, el
  /// backend rechazará la apertura — en vez de dejarlo fallar, guiamos el
  /// flujo natural: cerrar esa caja y luego aperturar la de la fecha actual.
  Future<void> _onAperturarTap() async {
    final cajaState = ref.read(cashRegisterProvider);
    if (!cajaState.openRegisterEsOtraFecha(_selectedDate)) {
      await showAperturarCajaSheet(context, fecha: _selectedDate);
      return;
    }

    final fechaAbierta = cajaState.openRegister!.fecha!;
    final fechaLabel = DateFormat('dd/MM/yyyy').format(fechaAbierta);
    final continuar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Caja pendiente de cierre',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: Text(
          'Para aperturar la caja de esta fecha primero debes cerrar la caja '
          'abierta del $fechaLabel. Te llevamos a su arqueo y, al cerrarla, '
          'volvemos aquí para aperturar.',
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
              backgroundColor: ColorSchema.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar y aperturar'),
          ),
        ],
      ),
    );
    if (continuar == true && mounted) {
      await _cerrarCajaAbiertaYAperturar(fechaAbierta, _selectedDate);
    }
  }

  /// Flujo encadenado: ir a la caja abierta → arqueo y cierre → volver a la
  /// fecha destino → sheet de apertura. Si el usuario cancela el arqueo,
  /// se queda viendo la caja abierta (decisión consciente).
  Future<void> _cerrarCajaAbiertaYAperturar(
      DateTime fechaAbierta, DateTime fechaDestino) async {
    final diaAbierta =
        DateTime(fechaAbierta.year, fechaAbierta.month, fechaAbierta.day);
    setState(() {
      _selectedDate = diaAbierta;
      _selectedRange = DateTimeRange(start: diaAbierta, end: diaAbierta);
      _selectedMoneda = null;
    });
    await _fetchCashRegister();
    if (!mounted) return;

    final cerrada = await showCerrarCajaSheet(context, fecha: diaAbierta);
    if (!cerrada || !mounted) return;

    final destino =
        DateTime(fechaDestino.year, fechaDestino.month, fechaDestino.day);
    setState(() {
      _selectedDate = destino;
      _selectedRange = DateTimeRange(start: destino, end: destino);
      _selectedMoneda = null;
    });
    await _fetchCashRegister();
    if (!mounted) return;
    await showAperturarCajaSheet(context, fecha: destino);
  }

  /// Salta a la fecha de la caja aperturada detectada (modo día) y recarga.
  void _goToOpenRegister(DateTime fecha) {
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    setState(() {
      _selectedDate = dia;
      _selectedRange = DateTimeRange(start: dia, end: dia);
      _selectedMoneda = null;
    });
    _fetchCashRegister();
  }

  /// Abre el sheet para registrar un ingreso/egreso externo del tipo activo.
  /// Requiere caja APERTURADA y permiso CAJA_INGRESO_EGRESO_CREAR (mismas
  /// reglas que la web; el botón ya se oculta, esto es la segunda defensa).
  Future<void> _openMovementSheet(String tipo, String monedaActiva) async {
    if (!ref.read(sesionProvider).hasPermission('CAJA_INGRESO_EGRESO_CREAR')) {
      warningNotification('No tienes permiso para registrar movimientos');
      return;
    }
    final cajaState = ref.read(cashRegisterProvider);
    final caja =
        cajaState.registers.isNotEmpty ? cajaState.registers.first : null;
    final idCaja = caja?.id;
    if (caja == null || idCaja == null) {
      warningNotification(
          'No hay una caja abierta para registrar movimientos');
      return;
    }
    if (!caja.isAperturada) {
      warningNotification(
          'La caja está cerrada: no se pueden registrar movimientos');
      return;
    }

    final ok = await showCashMovementSheet(
      context,
      tipo: tipo,
      idCaja: idCaja,
      turno: 1,
      monedaSugerida: monedaActiva,
    );

    if (ok && mounted) {
      setState(() => _selectedMoneda = null);
      _fetchCashRegister();
    }
  }

  String _fmt(Map<String, double> map, String moneda) {
    final symbol = formatExchange(moneda: moneda);
    final v = map[moneda] ?? 0.0;
    return '$symbol${v.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final sesion = ref.watch(sesionProvider);
    if (!sesion.hasPermission('CAJA_VER')) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded,
                  color: Colors.grey.shade400, size: 44),
              const SizedBox(height: 12),
              Text(
                'No tienes permisos para ver la caja',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                    fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    final cajaState = ref.watch(cashRegisterProvider);
    final detailState = ref.watch(cashRegisterDetailProvider);
    final puedeRegistrarMovimiento = cajaState.registers.isNotEmpty &&
        cajaState.registers.first.isAperturada &&
        sesion.hasPermission('CAJA_INGRESO_EGRESO_CREAR');

    final balance = cajaState.balancePorMoneda;
    final ingresos = cajaState.totalIngresosPorMoneda;
    final egresos = cajaState.totalEgresosPorMoneda;

    final monedas = cajaState.monedas;
    final monedaActiva = cajaState.monedaActiva(_selectedMoneda);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Selector de fecha / rango ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(top: 0, left: 8, right: 4),
          child: CustomDatePicker(
            onDateSelected: _onDateChanged,
            initialFilter: CalendarFilter.day,
            selectedRange: _selectedRange ??
                DateTimeRange(
                  start: DateTime(_selectedDate.year, _selectedDate.month,
                      _selectedDate.day),
                  end: DateTime(_selectedDate.year, _selectedDate.month,
                      _selectedDate.day),
                ),
          ),
        ),
        SizedBox(height: 12),
        // ── Aviso de caja abierta en otra fecha ────────────────────────────
        if (cajaState.openRegister?.fecha != null &&
            (!_isDayMode ||
                (!cajaState.isLoading &&
                    cajaState.openRegisterEsOtraFecha(_selectedDate))))
          OpenRegisterBanner(
            fecha: cajaState.openRegister!.fecha!,
            onTap: () => _goToOpenRegister(cajaState.openRegister!.fecha!),
          ),
        // ── Modo día: caja operativa ──────────────────────────────────────
        if (_isDayMode) ...[
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
                    : cajaState.registers.isEmpty
                    ? EmptyCajaCard(
                        fecha: _selectedDate,
                        onAperturar: sesion.hasPermission('CAJA_APERTURAR')
                            ? _onAperturarTap
                            : null,
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
                                if (cajaState.registers.isNotEmpty &&
                                    cajaState.registers.first.estadoCaja !=
                                        null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: cajaState.registers.first
                                              .isAperturada
                                          ? const Color(0xFF16A34A)
                                              .withValues(alpha: 0.1)
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      cajaState.registers.first.estadoCaja!,
                                      style: GoogleFonts.roboto(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: cajaState
                                                .registers.first.isAperturada
                                            ? const Color(0xFF16A34A)
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                if (monedas.length > 1) ...[
                                  CurrencySelector(
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
                                      MovimientoItem(
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
                                      MovimientoItem(
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

        // ── Botón ver balance + imprimir ───────────────────────────────────
        if (!cajaState.isLoading &&
            cajaState.registers.isNotEmpty &&
            cajaState.registers.first.id != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
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
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => ImprimirCajaModal(
                        idCaja: cajaState.registers.first.id!,
                        moneda: monedaActiva,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorSchema.primaryColor,
                      side: BorderSide(
                        color: ColorSchema.primaryColor.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    child: const Icon(Icons.print_rounded, size: 18),
                  ),
                ),
                if (cajaState.registers.first.isAperturada &&
                    sesion.hasPermission('CAJA_CERRAR')) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () =>
                          showCerrarCajaSheet(context, fecha: _selectedDate),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: BorderSide(
                          color:
                              const Color(0xFFDC2626).withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      child: const Icon(Icons.lock_outline_rounded, size: 18),
                    ),
                  ),
                ],
              ],
            ),
          ),

        const SizedBox(height: 12),

        // ── Selector Ingresos / Egresos (solo con caja existente) ─────────
        if (!cajaState.isLoading && cajaState.registers.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TipoSelector(
              tipo: detailState.tipo,
              isBlocked: detailState.isLoading || detailState.isLoadingMore,
              onChanged: (t) =>
                  ref.read(cashRegisterDetailProvider.notifier).changeTipo(t),
              onAdd: puedeRegistrarMovimiento
                  ? () => _openMovementSheet(detailState.tipo, monedaActiva)
                  : null,
            ),
          ),
          const SizedBox(height: 10),
        ],

        // ── Historial (solo esta parte scrollea) ───────────────────────────
        Expanded(
          child: _buildHistorialList(detailState, cajaState.isLoading),
        ),
        ] else
          // ── Modo reporte: resumen agregado del rango ────────────────────
          Expanded(
            child: CajaResumenView(
              state: ref.watch(cajaResumenProvider),
              selectedMoneda: _selectedMoneda,
              onMonedaChanged: (m) => setState(() => _selectedMoneda = m),
              onVerMovimientos: () =>
                  showRangoMovimientosSheet(context, range: _selectedRange!),
              onRetry: () => ref
                  .read(cajaResumenProvider.notifier)
                  .fetch(_selectedRange!),
            ),
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
          return HistorialItem(
            item: item,
            tipo: detailState.tipo,
          );
        },
      ),
    );
  }
}
