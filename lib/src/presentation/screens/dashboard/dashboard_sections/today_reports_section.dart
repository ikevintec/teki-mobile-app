import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart' hide Response;
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/response/cash_register_response.dart';
import 'package:teki_app/src/data/models/response/daily_sales_summary.dart';
import 'package:teki_app/src/data/repositories/cash_register_repository_impl.dart';
import 'package:teki_app/src/data/repositories/dashboard_repository_impl.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import '../navigation/dashboard_navigation.dart';
import 'package:teki_app/src/utils/constants.dart';

class TodayReportsSection extends ConsumerStatefulWidget {
  final int idPuntoVenta;
  final VoidCallback? onConnectionError;
  final VoidCallback? onLoadSuccess;

  /// Navega al tab de Caja (usado por el pill de estado y el banner).
  final VoidCallback? onIrACaja;

  const TodayReportsSection({
    super.key,
    required this.idPuntoVenta,
    this.onConnectionError,
    this.onLoadSuccess,
    this.onIrACaja,
  });

  @override
  ConsumerState<TodayReportsSection> createState() =>
      _TodayReportsSectionState();
}

class _TodayReportsSectionState extends ConsumerState<TodayReportsSection> {
  final DashboardRepositoryImpl _repo = DashboardRepositoryImpl();
  final CashRegisterRepositoryImpl _cajaRepo = CashRegisterRepositoryImpl();

  DailySalesSummary? ventasHoy;
  String? _selectedMoneda;
  bool loadingMontos = true;

  /// Caja del día de la estación de la sesión; null = sin aperturar o error.
  CashRegisterResponse? cajaHoy;
  bool cajaConsultada = false;
  bool loadingCaja = true;

  /// Caja APERTURADA con fecha distinta a hoy (banner de pendiente).
  CashRegisterResponse? cajaOtraFecha;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _isNetworkError(dynamic e) => e is DioException && e.response == null;

  Future<void> _load() async {
    final now = DateTime.now();
    final fmt = DateFormat('dd-MM-yyyy H:mm:ss');
    final desde = fmt.format(DateTime(now.year, now.month, now.day, 0, 0, 0));
    final hasta = fmt.format(
      DateTime(now.year, now.month, now.day, 23, 59, 59),
    );

    int networkFailures = 0;
    final session = ref.read(sesionProvider);
    final salesAllowed = dashboardAllows(session, 'VENTAS_VER');
    final cashAllowed = dashboardAllows(session, 'CAJA_VER');
    if (!salesAllowed) loadingMontos = false;
    if (!cashAllowed) loadingCaja = false;

    // Montos + nº de ventas del día en una sola consulta.
    final f1 = !salesAllowed
        ? Future<void>.value()
        : _repo
              .getTodaySalesSummary({
                'filtroEstadoAnulacion': 'false',
                'filtroDesde': desde,
                'filtroHasta': hasta,
                'idPuntoVenta': widget.idPuntoVenta.toString(),
              })
              .then((r) {
                if (!mounted) return;
                setState(() {
                  ventasHoy = r;
                  loadingMontos = false;
                });
              })
              .catchError((e) {
                if (_isNetworkError(e)) networkFailures++;
                if (!mounted) return;
                setState(() => loadingMontos = false);
              });

    final f2 = !cashAllowed
        ? Future<void>.value()
        : _loadCaja().catchError((e) {
            if (_isNetworkError(e)) networkFailures++;
            if (!mounted) return;
            setState(() => loadingCaja = false);
          });

    await Future.wait([f1, f2]);

    if (!mounted) return;
    if (networkFailures > 0 &&
        networkFailures == (salesAllowed ? 1 : 0) + (cashAllowed ? 1 : 0)) {
      widget.onConnectionError?.call();
    } else {
      widget.onLoadSuccess?.call();
    }
  }

  Future<void> _loadCaja() async {
    final sesion = ref.read(sesionProvider);
    final office = sesion.office;
    final station = sesion.saleStation;
    // La caja pertenece a la estación de la sesión.
    if (office?.id != widget.idPuntoVenta || station?.id == null) {
      if (mounted) setState(() => loadingCaja = false);
      return;
    }
    final hoy = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final results = await Future.wait([
      _cajaRepo.getCashRegister(
        idPuntoVenta: office!.id!,
        idEstacionVenta: station!.id!,
        fecha: hoy,
      ),
      _cajaRepo.getOpenCashRegisters(
        idPuntoVenta: office.id!,
        idEstacionVenta: station.id!,
      ),
    ]);
    if (!mounted) return;
    final cajas = results[0];
    final abiertas = results[1];
    setState(() {
      cajaConsultada = true;
      cajaHoy = cajas.where((c) => c.isAperturada).isNotEmpty
          ? cajas.firstWhere((c) => c.isAperturada)
          : (cajas.isNotEmpty ? cajas.first : null);
      cajaOtraFecha = abiertas.where((c) {
        final f = c.fecha;
        return f != null && DateFormat('dd-MM-yyyy').format(f) != hoy;
      }).firstOrNull;
      loadingCaja = false;
    });
  }

  List<String> get _monedas {
    if (ventasHoy == null) return [];
    final list = ventasHoy!.montos.map((m) => m.moneda).toList()
      ..sort((a, b) => a == 'PEN' ? -1 : 1);
    return list;
  }

  String get _monedaActiva {
    final list = _monedas;
    if (_selectedMoneda != null && list.contains(_selectedMoneda)) {
      return _selectedMoneda!;
    }
    return list.contains('PEN')
        ? 'PEN'
        : (list.isNotEmpty ? list.first : 'PEN');
  }

  String _simbolo(String codigo) => switch (codigo) {
    'PEN' => 'S/.',
    'USD' => '\$',
    'EUR' => '€',
    _ => codigo,
  };

  String _monto(String codigo) {
    if (ventasHoy == null) return '0.00';
    final entry = ventasHoy!.montos.where((m) => m.moneda == codigo);
    return (entry.isEmpty ? 0.0 : entry.first.monto).toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sesionProvider);
    final salesAllowed = dashboardAllows(session, 'VENTAS_VER');
    final cashAllowed = dashboardAllows(session, 'CAJA_VER');
    final open = cajaHoy?.isAperturada == true;
    final status = loadingCaja
        ? 'Consultando caja…'
        : !cajaConsultada
        ? 'Caja no disponible'
        : open
        ? 'Caja abierta'
        : cajaHoy == null
        ? 'Caja sin aperturar'
        : 'Caja cerrada';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (salesAllowed) ...[
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Ventas de hoy',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                if (_monedas.length > 1)
                  DropdownButton<String>(
                    value: _monedaActiva,
                    underline: const SizedBox.shrink(),
                    items: [
                      for (final m in _monedas)
                        DropdownMenuItem(value: m, child: Text(m)),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedMoneda = value),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              loadingMontos
                  ? 'Consultando ventas…'
                  : ventasHoy == null
                  ? 'Ventas no disponibles'
                  : '${_simbolo(_monedaActiva)} ${_monto(_monedaActiva)}',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: ColorSchema.titleTextColor,
              ),
            ),
            if (ventasHoy != null)
              Text(
                '${ventasHoy!.totalVentas} ${ventasHoy!.totalVentas == 1 ? 'comprobante' : 'comprobantes'}',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (cashAllowed)
                TextButton.icon(
                  onPressed: widget.onIrACaja,
                  icon: Icon(
                    Icons.point_of_sale_rounded,
                    size: 18,
                    color: open
                        ? const Color(0xFF176B4A)
                        : ColorSchema.primaryColor,
                  ),
                  label: Text(status),
                ),
              if (dashboardAllows(session, 'REPORTE_VENTAS'))
                TextButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.analytics),
                  icon: const Icon(Icons.bar_chart_rounded, size: 18),
                  label: const Text('Ver detalle'),
                ),
            ],
          ),
          if (cashAllowed && cajaOtraFecha?.fecha != null)
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: ColorSchema.primaryColor,
              ),
              onPressed: widget.onIrACaja,
              icon: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFF8B5D00),
              ),
              label: Text(
                'La caja del ${DateFormat('dd/MM').format(cajaOtraFecha!.fecha!)} sigue abierta',
                style: const TextStyle(color: Color(0xFF8B5D00)),
              ),
            ),
        ],
      ),
    );
  }
}
