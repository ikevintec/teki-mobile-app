import 'dart:async';

import 'package:flutter/material.dart' hide Table;
import 'package:teki_app/src/data/models/teki_model/table.dart';

class TableCard extends StatefulWidget {
  final Table table;
  final VoidCallback onTap;
  final bool showLounge;

  const TableCard({super.key, required this.table, required this.onTap, this.showLounge = false});

  @override
  State<TableCard> createState() => _TableCardState();
}

class _TableCardState extends State<TableCard> {
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateElapsed();
    });
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

    Color cardColor;
    Color textColor;
    String statusLabel;
    IconData statusIcon;

    // Paleta canónica de la WEB (los usuarios ya la conocen):
    // items preparados = verde (listo), PENDIENTE = ámbar,
    // PRECUENTA = morado (status-renewal), libre = gris.
    if (hasItemPreparado) {
      cardColor = const Color(0xFFE8F5E9);
      textColor = const Color(0xFF256029);
      statusLabel = 'Preparado';
      statusIcon = Icons.room_service_rounded;
    } else if (estado == 'PENDIENTE') {
      cardColor = const Color(0xFFFEEDAF);
      textColor = const Color(0xFF8A5340);
      statusLabel = 'Pendiente';
      statusIcon = Icons.receipt_long;
    } else if (estado == 'PRECUENTA') {
      cardColor = const Color(0xFFECCFFF);
      textColor = const Color(0xFF694382);
      statusLabel = 'Precuenta';
      statusIcon = Icons.payment;
    } else {
      cardColor = Colors.grey.shade100;
      textColor = Colors.grey.shade600;
      statusLabel = 'Libre';
      statusIcon = Icons.chair;
    }

    final hasOrder = order != null && order.id != null;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: textColor.withValues(alpha: 0.25), width: 3),
          boxShadow: [
            BoxShadow(
              color: textColor.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            color: cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Línea de acento superior
                Container(height: 4, color: textColor),
                // Cuerpo
                Expanded(
                  child: Stack(
                    children: [
                      // Ícono independiente — esquina superior derecha
                      Positioned(
                        top: 10,
                        right: 12,
                        child: Icon(statusIcon, color: textColor, size: 24),
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
                              _infoRow(icon: Icons.access_time_rounded, label: _formatElapsed(_elapsed), textColor: textColor, bold: true),
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

  int _totalItems(dynamic order) {
    int total = 0;
    for (final comanda in (order.comandas ?? [])) {
      total += (comanda.items?.length ?? 0) as int;
    }
    return total;
  }

  double _totalOrder(dynamic order) {
    double total = 0;
    for (final comanda in (order.comandas ?? [])) {
      for (final item in (comanda.items ?? [])) {
        if (item.eliminado == true ||
            item.estadoComandaDetalle?.toUpperCase() == 'CANCELADO') {
          continue;
        }
        total += ((item.precioVenta ?? 0) * (item.cantidad ?? 1)) as double;
      }
    }
    return total;
  }
}
