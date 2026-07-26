import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/response/cash_register_response.dart';
import 'package:teki_app/src/data/models/response/daily_sales_summary.dart';
import 'package:teki_app/src/data/models/response/top_product.dart';
import 'package:teki_app/src/data/models/teki_model/monthly_movement.dart';
import 'package:teki_app/src/data/models/teki_model/monthly_sales.dart';
import 'package:teki_app/src/data/repositories/cash_register_repository_impl.dart';
import 'package:teki_app/src/data/repositories/dashboard_repository_impl.dart';
import 'package:teki_app/src/data/repositories/monthly_movement_impl.dart';
import 'package:teki_app/src/data/repositories/monthlysales_impl.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/constants.dart';

/// KPIs del dashboard: ventas de hoy, estado de caja, resumen del mes y
/// top de productos. Cada bloque carga de forma independiente (sin loader
/// bloqueante): si una consulta tarda o falla, el resto sigue visible.
class AnalyticsReportSection extends ConsumerStatefulWidget {
  final int idPuntoVenta;

  const AnalyticsReportSection({super.key, required this.idPuntoVenta});

  @override
  ConsumerState<AnalyticsReportSection> createState() =>
      _AnalyticsReportSectionState();
}

class _AnalyticsReportSectionState
    extends ConsumerState<AnalyticsReportSection> {
  final _dashboardRepo = DashboardRepositoryImpl();
  final _cajaRepo = CashRegisterRepositoryImpl();
  final _salesRepo = MonthlySalesRepositoryImpl();
  final _movementsRepo = MovementMonthRepositoryImpl();

  DailySalesSummary? _ventasHoy;
  bool _loadingVentasHoy = true;

  CashRegisterResponse? _cajaHoy;
  bool _cajaSinAperturar = false;
  bool _loadingCaja = true;

  List<MonthlySales> _ventasMes = [];
  List<MonthlyMovement> _movimientosMes = [];
  bool _loadingMes = true;

  List<TopProduct> _topProductos = [];
  bool _loadingTop = true;

  /// Invalida respuestas de cargas anteriores al cambiar de punto de venta.
  int _loadSeq = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void didUpdateWidget(covariant AnalyticsReportSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.idPuntoVenta != widget.idPuntoVenta) {
      _loadAll();
    }
  }

  void _loadAll() {
    final seq = ++_loadSeq;
    setState(() {
      _loadingVentasHoy = true;
      _loadingCaja = true;
      _loadingMes = true;
      _loadingTop = true;
    });
    _loadVentasHoy(seq);
    _loadCaja(seq);
    _loadMes(seq);
    _loadTop(seq);
  }

  String _fmtDate(DateTime d) => DateFormat('dd-MM-yyyy').format(d);

  Future<void> _loadVentasHoy(int seq) async {
    try {
      final now = DateTime.now();
      final dateFormat = DateFormat('dd-MM-yyyy H:mm:ss');
      final result = await _dashboardRepo.getTodaySalesSummary({
        'filtroEstadoAnulacion': 'false',
        'filtroDesde':
            dateFormat.format(DateTime(now.year, now.month, now.day)),
        'filtroHasta':
            dateFormat.format(DateTime(now.year, now.month, now.day, 23, 59, 59)),
        'idPuntoVenta': widget.idPuntoVenta.toString(),
      });
      if (mounted && seq == _loadSeq) setState(() => _ventasHoy = result);
    } catch (_) {
      // El bloque queda en '—'; sin toast para no interrumpir el dashboard.
    } finally {
      if (mounted && seq == _loadSeq) setState(() => _loadingVentasHoy = false);
    }
  }

  Future<void> _loadCaja(int seq) async {
    final sesion = ref.read(sesionProvider);
    final office = sesion.office;
    final station = sesion.saleStation;
    // La caja pertenece a la estación de la sesión: solo aplica cuando el
    // punto de venta seleccionado es el de la sesión.
    if (office?.id != widget.idPuntoVenta || station?.id == null) {
      if (mounted && seq == _loadSeq) {
        setState(() {
          _cajaHoy = null;
          _cajaSinAperturar = false;
          _loadingCaja = false;
        });
      }
      return;
    }
    try {
      final cajas = await _cajaRepo.getCashRegister(
        idPuntoVenta: office!.id!,
        idEstacionVenta: station!.id!,
        fecha: _fmtDate(DateTime.now()),
      );
      if (mounted && seq == _loadSeq) {
        setState(() {
          _cajaHoy = cajas.where((c) => c.isAperturada).isNotEmpty
              ? cajas.firstWhere((c) => c.isAperturada)
              : (cajas.isNotEmpty ? cajas.first : null);
          _cajaSinAperturar = cajas.isEmpty;
        });
      }
    } catch (_) {
      // Silencioso: el card mostrará '—'.
    } finally {
      if (mounted && seq == _loadSeq) setState(() => _loadingCaja = false);
    }
  }

  Future<void> _loadMes(int seq) async {
    try {
      final results = await Future.wait([
        _salesRepo.getSales(widget.idPuntoVenta),
        _movementsRepo.getMovementsBySalePoint(widget.idPuntoVenta),
      ]);
      if (mounted && seq == _loadSeq) {
        setState(() {
          _ventasMes = results[0] as List<MonthlySales>;
          _movimientosMes = results[1] as List<MonthlyMovement>;
        });
      }
    } catch (_) {
      // Silencioso: los mini-cards mostrarán '—'.
    } finally {
      if (mounted && seq == _loadSeq) setState(() => _loadingMes = false);
    }
  }

  Future<void> _loadTop(int seq) async {
    try {
      final now = DateTime.now();
      final result = await _dashboardRepo.getTopProducts({
        'filtroDesde': _fmtDate(now.subtract(const Duration(days: 6))),
        'filtroHasta': _fmtDate(now),
        'idPuntoVenta': widget.idPuntoVenta.toString(),
        'top': '5',
      });
      if (mounted && seq == _loadSeq) setState(() => _topProductos = result);
    } catch (_) {
      // Silencioso: la sección se oculta si no hay datos.
    } finally {
      if (mounted && seq == _loadSeq) setState(() => _loadingTop = false);
    }
  }

  // ── Derivados ──────────────────────────────────────────────────────────

  static String _simbolo(String moneda) => switch (moneda) {
        'PEN' => 'S/',
        'USD' => '\$',
        'EUR' => '€',
        _ => moneda,
      };

  static String _fmtMonto(double v) =>
      NumberFormat('#,##0.00', 'es_PE').format(v);

  /// Moneda principal de los datos del mes (PEN si está presente).
  String get _monedaPrincipal {
    final monedas = _ventasMes.map((e) => e.moneda).toSet();
    if (monedas.isEmpty || monedas.contains('PEN')) return 'PEN';
    return monedas.first;
  }

  String get _periodoActual => DateFormat('yyyy-MM').format(DateTime.now());

  String get _periodoAnterior {
    final now = DateTime.now();
    return DateFormat('yyyy-MM').format(DateTime(now.year, now.month - 1, 1));
  }

  double _totalVentasPeriodo(String periodo) => _ventasMes
      .where((e) => e.periodo == periodo && e.moneda == _monedaPrincipal)
      .fold(0.0, (s, e) => s + e.total);

  double get _egresosMesActual => _movimientosMes
      .where((e) => e.periodo == _periodoActual && e.moneda == _monedaPrincipal)
      .fold(0.0, (s, e) => s + e.totalEgresos);

  /// Variación % de ventas vs el mes anterior; null si no hay base de
  /// comparación (mes anterior en 0).
  double? get _deltaMes {
    final anterior = _totalVentasPeriodo(_periodoAnterior);
    if (anterior == 0) return null;
    return (_totalVentasPeriodo(_periodoActual) - anterior) / anterior * 100;
  }

  // ── UI ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          _sectionLabel('HOY'),
          // IntrinsicHeight acota la altura de la fila: dentro del ListView
          // la altura es no acotada y stretch a secas fuerza altura infinita
          // (rompe el layout y desata asserts de semantics en cascada).
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: _buildVentasHoyCard()),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: _buildCajaCard()),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildMiniMesCard(
                label: 'Ventas del mes',
                value: _loadingMes
                    ? null
                    : '${_simbolo(_monedaPrincipal)} ${_fmtMonto(_totalVentasPeriodo(_periodoActual))}',
                delta: _loadingMes ? null : _deltaMes,
              )),
              const SizedBox(width: 8),
              Expanded(child: _buildMiniMesCard(
                label: 'Egresos del mes',
                value: _loadingMes
                    ? null
                    : '${_simbolo(_monedaPrincipal)} ${_fmtMonto(_egresosMesActual)}',
              )),
            ],
          ),
          if (_loadingTop || _topProductos.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionLabel('TOP PRODUCTOS (7 DÍAS)'),
            _buildTopProductos(),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        text,
        style: GoogleFonts.roboto(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget _buildVentasHoyCard() {
    final montos = _ventasHoy?.montos ?? [];
    final principal = montos.where((m) => m.moneda == 'PEN').isNotEmpty
        ? montos.firstWhere((m) => m.moneda == 'PEN')
        : (montos.isNotEmpty ? montos.first : null);
    final otros = montos.where((m) => m != principal).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ColorSchema.primaryColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: _loadingVentasHoy
          ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ventas de hoy',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  principal == null
                      ? '—'
                      : '${_simbolo(principal.moneda)} ${_fmtMonto(principal.monto)}',
                  style: GoogleFonts.roboto(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                for (final m in otros)
                  Text(
                    '${_simbolo(m.moneda)} ${_fmtMonto(m.monto)}',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  principal == null
                      ? 'Sin ventas registradas'
                      : '${_ventasHoy!.totalVentas} venta(s) · ticket prom. '
                          '${_simbolo(principal.moneda)} ${_fmtMonto(_ventasHoy!.ticketPromedio(principal.moneda))}',
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCajaCard() {
    final sesion = ref.watch(sesionProvider);
    final aplicaSesion = sesion.office?.id == widget.idPuntoVenta;

    final Color bg;
    final Color fg;
    final String estado;
    final String detalle;

    if (!aplicaSesion) {
      bg = Colors.grey.shade100;
      fg = Colors.grey.shade600;
      estado = '—';
      detalle = 'Solo disponible para tu estación';
    } else if (_cajaSinAperturar) {
      bg = const Color(0xFFFFF8E1);
      fg = const Color(0xFF9B6F00);
      estado = 'Sin aperturar';
      detalle = 'Apertura la caja para operar';
    } else if (_cajaHoy?.isAperturada == true) {
      bg = const Color(0xFFE8F5E9);
      fg = const Color(0xFF2E7D32);
      estado = 'Abierta';
      final ingresos = _cajaHoy!.montosTotalesIngresos
          .where((m) => m.moneda == 'PEN')
          .toList();
      detalle = ingresos.isEmpty
          ? 'Sin movimientos aún'
          : 'Ingresos: S/ ${_fmtMonto(ingresos.first.monto)}';
    } else if (_cajaHoy != null) {
      bg = Colors.grey.shade100;
      fg = Colors.grey.shade700;
      estado = 'Cerrada';
      detalle = 'Caja del día arqueada';
    } else {
      bg = Colors.grey.shade100;
      fg = Colors.grey.shade600;
      estado = '—';
      detalle = 'No se pudo consultar';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: _loadingCaja
          ? Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: fg, strokeWidth: 2),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.point_of_sale_rounded, size: 14, color: fg),
                    const SizedBox(width: 4),
                    Text(
                      'Caja',
                      style: GoogleFonts.roboto(fontSize: 12, color: fg),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  estado,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detalle,
                  style: GoogleFonts.roboto(fontSize: 10.5, color: fg.withValues(alpha: 0.85)),
                ),
              ],
            ),
    );
  }

  Widget _buildMiniMesCard({required String label, String? value, double? delta}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Flexible(
                child: Text(
                  value ?? '—',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (delta != null) ...[
                const SizedBox(width: 4),
                Text(
                  '${delta >= 0 ? '▲' : '▼'} ${delta.abs().toStringAsFixed(0)}%',
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: delta >= 0
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC62828),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductos() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: _loadingTop
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: ColorSchema.primaryColor),
                ),
              ),
            )
          : Column(
              children: [
                for (int i = 0; i < _topProductos.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: i == _topProductos.length - 1
                          ? null
                          : Border(bottom: BorderSide(color: Colors.grey.shade100)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: i == 0
                                ? const Color(0xFFFFF3E0)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${i + 1}',
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: i == 0
                                  ? const Color(0xFFE65100)
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _topProductos[i].nombreProducto,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(fontSize: 13),
                          ),
                        ),
                        Text(
                          '${_topProductos[i].cantidad % 1 == 0 ? _topProductos[i].cantidad.toInt() : _topProductos[i].cantidad} und',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
