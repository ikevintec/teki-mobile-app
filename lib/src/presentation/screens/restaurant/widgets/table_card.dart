import 'dart:async';

import 'package:flutter/material.dart' hide Table;
import 'package:teki_app/src/data/models/teki_model/table.dart';
import 'package:teki_app/src/presentation/screens/restaurant/widgets/restaurant_table_palette.dart';

class TableCard extends StatefulWidget {
  final Table table;
  final VoidCallback onTap;
  final bool showLounge;

  const TableCard({super.key, required this.table, required this.onTap, this.showLounge = false});

  @override
  State<TableCard> createState() => _TableCardState();
}

class _TableCardState extends State<TableCard> with SingleTickerProviderStateMixin {
  late Timer _timer;
  late final AnimationController _alertController;
  late final Animation<double> _alertPulse;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _alertController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _alertPulse = CurvedAnimation(parent: _alertController, curve: Curves.easeInOut);
    _syncAlertAnimation();
    _updateElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateElapsed();
    });
  }

  @override
  void didUpdateWidget(covariant TableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAlertAnimation();
  }

  bool get _isCalling => widget.table.llamadaEn != null;

  bool get _isAccountRequested {
    final order = widget.table.pedidoActual;
    return order?.cuentaSolicitadaEn != null && order?.estado != 'PRECUENTA';
  }

  void _syncAlertAnimation() {
    if (_isCalling || _isAccountRequested) {
      if (!_alertController.isAnimating) _alertController.repeat(reverse: true);
    } else {
      _alertController.stop();
      _alertController.value = 0;
    }
  }

  void _updateElapsed() {
    final fecha = widget.table.pedidoActual?.fecha;
    setState(() {
      _elapsed = fecha != null ? DateTime.now().difference(fecha) : Duration.zero;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _alertController.dispose();
    super.dispose();
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '${h}h ${m}m';
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final table = widget.table;
    final order = table.pedidoActual;
    final estado = order?.estado;
    final loungeLabel = widget.showLounge ? (table.salon?.nombre) : null;

    // Detect if any item in any comanda is PREPARADO
    final hasItemPreparado = estado == 'PENDIENTE' &&
        (order?.comandas ?? []).any(
          (c) => (c.items ?? []).any(
            (item) =>
                item.estadoComandaDetalle?.toUpperCase() == 'PREPARADO' &&
                item.eliminado != true,
          ),
        );

    Color baseColor;
    String statusLabel;
    IconData statusIcon;

    // Misma semántica y colores del mapa de mesas web (paleta canónica).
    if (hasItemPreparado) {
      baseColor = RestaurantTablePalette.prepared;
      statusLabel = 'Preparado';
      statusIcon = Icons.room_service_rounded;
    } else if (estado == 'PENDIENTE') {
      baseColor = RestaurantTablePalette.order;
      statusLabel = 'Pedido';
      statusIcon = Icons.receipt_long;
    } else if (estado == 'PRECUENTA') {
      baseColor = RestaurantTablePalette.paying;
      statusLabel = 'Pagando';
      statusIcon = Icons.payment;
    } else {
      baseColor = RestaurantTablePalette.free;
      statusLabel = 'Libre';
      statusIcon = Icons.chair;
    }

    // Entonación previa: fondo tenue + texto oscuro derivados del color
    // semántico, para conservar contraste y legibilidad de las tarjetas.
    final cardColor = Color.lerp(baseColor, Colors.white, 0.85)!;
    final textColor = Color.lerp(baseColor, Colors.black, 0.45)!;

    final hasOrder = order != null && order.id != null;
    final isQrOrigin = _isQrOrigin(order);
    final isCalling = _isCalling;
    final isAccountRequested = _isAccountRequested;

    return AnimatedBuilder(
      animation: _alertController,
      builder: (context, _) {
        final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        final pulse = reduceMotion ? 0.0 : _alertPulse.value;
        const accountColor = Color(0xFF047857);

        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            key: const Key('table-card-container'),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isAccountRequested
                    ? Color.lerp(textColor.withValues(alpha: 0.25), accountColor, 0.45 + (pulse * 0.55))!
                    : textColor.withValues(alpha: 0.25),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: textColor.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
          // Radio interno = radio externo (14) - grosor del borde (3), para
          // que el contenido (franja/acento) quede al ras del borde y no deje
          // el pequeño espacio en las esquinas.
          borderRadius: BorderRadius.circular(11),
          child: Container(
            color: cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Línea de acento superior — se convierte en franja
                // "LLAMANDO" cuando el comensal llama al camarero, para no
                // empujar la data del cuerpo (evita el overflow anterior).
                if (isCalling)
                  _callingStrip(pulse)
                else
                  Container(height: 4, color: textColor),
                // Cuerpo
                Expanded(
                  child: Stack(
                    children: [
                      // Ícono de estado (+ marca QR) — esquina superior derecha.
                      // Se mantiene en horizontal para no ocupar alto.
                      Positioned(
                        top: 10,
                        right: 12,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isQrOrigin) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: textColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.qr_code_rounded, size: 11, color: textColor),
                                    const SizedBox(width: 3),
                                    Text(
                                      'QR',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: textColor,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            // Cuando el comensal pidió la cuenta, el propio
                            // icono de estado pasa a ser el recibo verde
                            // pulsante (una sola señal, sin badge extra).
                            if (isAccountRequested)
                              Tooltip(
                                message: 'El comensal pidió la cuenta',
                                child: SizedBox(
                                  width: 34,
                                  height: 34,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Halo que late detrás del icono para
                                      // que la señal resalte más.
                                      Container(
                                        width: 20 + (pulse * 14),
                                        height: 20 + (pulse * 14),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: accountColor.withValues(
                                            alpha: 0.28 * (1 - pulse),
                                          ),
                                        ),
                                      ),
                                      Transform.scale(
                                        scale: 1 + (pulse * 0.22),
                                        child: Icon(
                                          Icons.receipt_long_rounded,
                                          color: accountColor,
                                          size: 24,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Icon(statusIcon, color: textColor, size: 24),
                          ],
                        ),
                      ),
                      // Total independiente — esquina inferior derecha
                      if (hasOrder)
                        Positioned(
                          bottom: 10,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: textColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'S/. ${_totalOrder(order).toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Piso pegado al número de mesa
                            if (loungeLabel != null)
                              Text(
                                loungeLabel,
                                style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.7), fontWeight: FontWeight.w600),
                              ),
                            // Número de mesa
                            Text(
                              'Mesa ${table.numero ?? table.id}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: textColor),
                            ),
                            const Spacer(),
                            // Info inferior izquierda
                            if (!hasOrder)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(
                                  color: textColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w700),
                                ),
                              ),
                            if (hasOrder) ...[
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: textColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  if ((order.numeroComensales ?? 0) > 0) ...[
                                    const SizedBox(width: 8),
                                    Icon(Icons.people_outline, size: 11, color: textColor.withValues(alpha: 0.6)),
                                    const SizedBox(width: 4),
                                    Text('${order.numeroComensales}', style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.75))),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              if (order.usuario?.nombreCompleto != null) ...[
                                _infoRow(icon: Icons.person_outline, label: order.usuario!.nombreCompleto!, textColor: textColor),
                                const SizedBox(height: 3),
                              ],
                              _infoRow(icon: Icons.restaurant_menu, label: '${_totalItems(order)} items', textColor: textColor),
                              const SizedBox(height: 3),
                              // El tiempo escala de color con la espera:
                              // >45 min naranja, >90 min rojo.
                              _infoRow(
                                icon: Icons.access_time_rounded,
                                label: _formatElapsed(_elapsed),
                                textColor: _elapsed.inMinutes >= 90
                                    ? const Color(0xFFC62828)
                                    : _elapsed.inMinutes >= 45
                                        ? const Color(0xFFE65100)
                                        : textColor,
                                bold: true,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
            ),
          ),
        );
      },
    );
  }

  /// Franja superior animada que reemplaza la línea de acento cuando el
  /// comensal llama al camarero. Vive fuera del flujo vertical del cuerpo,
  /// por lo que no empuja la data ni provoca overflow. El color pulsa entre
  /// dos rojos según [pulse] (0 = sin animación, respeta "reduce motion").
  Widget _callingStrip(double pulse) {
    return Semantics(
      label: 'El comensal llama al camarero',
      child: Container(
        key: const Key('table-call-alert'),
        height: 20,
        width: double.infinity,
        color: Color.lerp(
          const Color(0xFFB91C1C),
          const Color(0xFFEF4444),
          pulse,
        ),
        alignment: Alignment.center,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_active_rounded, size: 12, color: Colors.white),
            SizedBox(width: 5),
            Text(
              'LLAMANDO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({required IconData icon, required String label, required Color textColor, bool bold = false}) {
    return Row(
      children: [
        Icon(icon, size: 11, color: textColor.withValues(alpha: 0.6)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textColor.withValues(alpha: bold ? 0.9 : 0.75),
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// ¿El pedido se originó por QR? Reforzado para datos incompletos:
  /// 1) usa el flag del pedido `esPedidoQr` cuando llega (true/false),
  /// 2) si el campo no llega (null), lo deriva de la comanda original
  ///    (`esPorQr` de la comanda con menor `orden`),
  /// 3) ante ausencia total de datos, devuelve false (no marca la mesa).
  bool _isQrOrigin(dynamic order) {
    if (order == null || order.id == null) return false;

    final flag = order.esPedidoQr;
    if (flag is bool) return flag;

    final List comandas = order.comandas ?? const [];
    if (comandas.isEmpty) return false;

    dynamic original;
    for (final c in comandas) {
      if (original == null) {
        original = c;
        continue;
      }
      final ordenC = (c.orden as int?) ?? 1 << 30;
      final ordenOriginal = (original.orden as int?) ?? 1 << 30;
      if (ordenC < ordenOriginal) original = c;
    }
    return original?.esPorQr == true;
  }

  int _totalItems(dynamic order) {
    int total = 0;
    for (final comanda in (order.comandas ?? [])) {
      for (final item in (comanda.items ?? [])) {
        final status = item.estadoComandaDetalle?.toUpperCase();
        if (item.eliminado == true ||
            const {'CANCELADO', 'RECHAZADO'}.contains(status)) {
          continue;
        }
        total++;
      }
    }
    return total;
  }

  double _totalOrder(dynamic order) {
    double total = 0;
    for (final comanda in (order.comandas ?? [])) {
      for (final item in (comanda.items ?? [])) {
        if (item.eliminado == true ||
            const {'CANCELADO', 'RECHAZADO'}.contains(
              item.estadoComandaDetalle?.toUpperCase(),
            )) {
          continue;
        }
        total += ((item.precioVenta ?? 0) * (item.cantidad ?? 1)) as double;
      }
    }
    return total;
  }
}
