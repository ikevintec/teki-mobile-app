import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/customer.dart';
import 'package:teki_app/src/data/models/teki_model/ticket_detail.dart';
import 'pedidos_style.dart';

/// Lectura del carrito actual. No recalcula, guarda ni envía el pedido.
class ResumenPedido extends StatelessWidget {
  final Customer cliente;
  final String? comprobante;
  final String moneda, observacion;
  final List<TicketDetail> lineas;
  final double total;
  final DateTime? entrega;
  final bool bonificacionesPendientes;

  const ResumenPedido({
    super.key,
    required this.cliente,
    required this.comprobante,
    required this.moneda,
    required this.lineas,
    required this.total,
    required this.observacion,
    this.entrega,
    this.bonificacionesPendientes = false,
  });

  @override
  Widget build(BuildContext context) => PedidosStyle(
    child: Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: MediaQuery.sizeOf(context).height * .88,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Resumen del pedido',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar resumen',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Text(
                      cliente.razonSocial ?? 'Sin cliente seleccionado',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (cliente.numeroDocumento?.isNotEmpty == true)
                      Text(cliente.numeroDocumento!),
                    Text(
                      const {
                            '01': 'Factura',
                            '03': 'Boleta',
                            'NV': 'Nota de venta',
                          }[comprobante] ??
                          'Sin comprobante seleccionado',
                    ),
                    const SizedBox(height: 16),
                    if (bonificacionesPendientes)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Hay bonificaciones por resolver antes de enviar.',
                        ),
                      ),
                    if (lineas.isEmpty)
                      const Text('Aún no has agregado productos.'),
                    for (final l in lineas) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (l.esBonificacion == true)
                            const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Icon(Icons.card_giftcard, size: 20),
                            ),
                          Expanded(
                            child: Text(
                              l.descripcion ?? 'Producto',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * .3,
                            ),
                            child: Text(
                              l.esBonificacion == true
                                  ? 'Gratis'
                                  : '$moneda ${l.precioTotal?.toStringAsFixed(2) ?? '—'}',
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${l.cantidad ?? 0} ${l.codigoUnidadMedida ?? ''}'
                        '${l.esBonificacion == true ? ' · Bonificación' : ' × $moneda ${l.precioVentaUnitario?.toStringAsFixed(2) ?? '—'}'}'
                        '${l.esBonificacion != true && l.tipoComercialNombre != null ? ' · ${l.tipoComercialNombre}' : ''}',
                      ),
                      const Divider(height: 16),
                    ],
                    if (entrega != null)
                      Text(
                        'Entrega: ${DateFormat('dd/MM/yyyy').format(entrega!)}',
                      ),
                    if (observacion.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Observaciones: $observacion'),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'Total $moneda ${total.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Volver al pedido'),
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
