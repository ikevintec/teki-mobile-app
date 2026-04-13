import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/repositories/dashboard_repository_impl.dart';
import 'package:teki_app/src/routes/app_routes.dart';

class TodayReportsSection extends StatefulWidget {
  final int idPuntoVenta;
  const TodayReportsSection({super.key, required this.idPuntoVenta});

  @override
  State<TodayReportsSection> createState() => _TodayReportsSectionState();
}

class _TodayReportsSectionState extends State<TodayReportsSection> {
  final DashboardRepositoryImpl _repo = DashboardRepositoryImpl();

  int? totalClientes;
  int? totalVentas;
  List<Map<String, dynamic>>? montosPorMoneda;
  String? _selectedMoneda;

  bool loadingClientes = true;
  bool loadingVentas = true;
  bool loadingMontos = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final fmt = DateFormat('dd-MM-yyyy H:mm:ss');
    final desde = fmt.format(DateTime(now.year, now.month, now.day, 0, 0, 0));
    final hasta = fmt.format(DateTime(now.year, now.month, now.day, 23, 59, 59));

    _repo.getCustomerCount().then((r) {
      if (!mounted) return;
      setState(() { totalClientes = r.total; loadingClientes = false; });
    }).catchError((_) {
      if (!mounted) return;
      setState(() => loadingClientes = false);
    });

    _repo.getSalesCount(widget.idPuntoVenta).then((r) {
      if (!mounted) return;
      setState(() { totalVentas = r.total; loadingVentas = false; });
    }).catchError((_) {
      if (!mounted) return;
      setState(() => loadingVentas = false);
    });

    _repo.getAmountsByCurrency({
      'filtroEstadoAnulacion': 'false',
      'filtroDesde': desde,
      'filtroHasta': hasta,
      'idPuntoVenta': widget.idPuntoVenta.toString(),
    }).then((r) {
      if (!mounted) return;
      setState(() { montosPorMoneda = r; loadingMontos = false; });
    }).catchError((e) {
      printError(info: '❌ Error montos: $e');
      if (!mounted) return;
      setState(() => loadingMontos = false);
    });
  }

  List<String> get _monedas {
    if (montosPorMoneda == null) return [];
    final list = montosPorMoneda!
        .map((m) => m['codigoMoneda'] as String? ?? '')
        .where((c) => c.isNotEmpty)
        .toList()
      ..sort((a, b) => a == 'PEN' ? -1 : 1);
    return list;
  }

  String get _monedaActiva {
    final list = _monedas;
    if (_selectedMoneda != null && list.contains(_selectedMoneda)) {
      return _selectedMoneda!;
    }
    return list.contains('PEN') ? 'PEN' : (list.isNotEmpty ? list.first : 'PEN');
  }

  String _simbolo(String codigo) => switch (codigo) {
    'PEN' => 'S/.',
    'USD' => '\$',
    'EUR' => '€',
    _ => codigo,
  };

  String _monto(String codigo) {
    if (montosPorMoneda == null) return '0.00';
    final entry = montosPorMoneda!.firstWhere(
      (m) => m['codigoMoneda'] == codigo,
      orElse: () => {},
    );
    return (entry['monto'] ?? 0).toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, d \'de\' MMMM', 'es').format(DateTime.now());
    final todayLabel = today[0].toUpperCase() + today.substring(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Tarjeta principal ──────────────────────────────────────────
          Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(255, 14, 78, 210),
                    Color.fromARGB(255, 56, 152, 236),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(255, 14, 78, 210).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Círculo decorativo
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    right: 60,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                  ),

                  Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Monto (izq) | selector (der) ───────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: loadingMontos
                          ? _Skeleton(width: 160, height: 36)
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: Center(
                                    child: SvgPicture.asset(
                                      'assets/icons/icon_svg/sale_service_icon.svg',
                                      colorFilter: const ColorFilter.mode(
                                          Colors.white, BlendMode.srcIn),
                                      width: 19,
                                      height: 19,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _simbolo(_monedaActiva),
                                          style: GoogleFonts.nunito(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white.withValues(alpha: 0.9),
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          _monto(_monedaActiva),
                                          style: GoogleFonts.nunito(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            height: 1.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                    if (!loadingMontos && _monedas.length > 1)
                      GestureDetector(
                        // Evita que el tap del selector propague al card
                        onTap: () {},
                        child: _MonedaSelector(
                          monedas: _monedas,
                          value: _monedaActiva,
                          onChanged: (v) => setState(() => _selectedMoneda = v),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 2),
                Text(
                  todayLabel,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),

                const SizedBox(height: 18),

                // ── Divisor ─────────────────────────────────────────────
                Divider(
                  color: Colors.white.withValues(alpha: 0.12),
                  height: 1,
                ),

                const SizedBox(height: 16),

                // ── Métricas secundarias ────────────────────────────────
                Row(
                  children: [
                    _SecondaryMetric(
                      icon: 'assets/icons/icon_svg/purchase_service_icon.svg',
                      label: 'Ventas Cerradas',
                      value: loadingVentas ? '---' : '${totalVentas ?? 0}',
                      loading: loadingVentas,
                    ),
                    _VerticalDivider(),
                    _SecondaryMetric(
                      icon: 'assets/icons/icon_svg/expenses_icon.svg',
                      label: 'Clientes',
                      value: loadingClientes ? '---' : '${totalClientes ?? 0}',
                      loading: loadingClientes,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),

          // ── Chip "Ver detalles" en el borde superior derecho ───────────
          Positioned(
            top: -15,
            right: 0,
            child: GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.analytics),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 14, 78, 210),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver detalles',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryMetric extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final bool loading;

  const _SecondaryMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Center(
              child: SvgPicture.asset(
                icon,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                width: 19,
                height: 19,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              loading
                  ? _Skeleton(width: 36, height: 14)
                  : Text(
                      value,
                      style: GoogleFonts.nunito(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white.withValues(alpha: 0.12),
    );
  }
}

class _Skeleton extends StatelessWidget {
  final double width;
  final double height;

  const _Skeleton({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

/// Selector de moneda con overlay — no dispara navegación ni RouteObserver.
class _MonedaSelector extends StatefulWidget {
  final List<String> monedas;
  final String value;
  final ValueChanged<String> onChanged;

  const _MonedaSelector({
    required this.monedas,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_MonedaSelector> createState() => _MonedaSelectorState();
}

class _MonedaSelectorState extends State<_MonedaSelector> {
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

  void _select(String m) {
    _close();
    widget.onChanged(m);
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
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: const Offset(0, 6),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D3BA0),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
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
                    final sel = m == widget.value;
                    return InkWell(
                      onTap: () => _select(m),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            if (sel)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(Icons.check_rounded,
                                    size: 13, color: Colors.white),
                              ),
                            Text(
                              m,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                color: sel
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.65),
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
            color: Colors.white.withValues(alpha: _open ? 0.2 : 0.13),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.value,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 2),
              AnimatedRotation(
                turns: _open ? 0.5 : 0,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 15,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
