import 'package:flutter/material.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';

/// Tips remain separate from the sale total, including in the full editor.
class RestaurantTipSummary extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onRemove;
  const RestaurantTipSummary({super.key, required this.ticket, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final amount = ticket.propina ?? 0;
    if (amount <= 0) return const SizedBox.shrink();
    final symbol = ticket.codigoMoneda == 'USD' ? r'$ ' : 'S/ ';
    final waiter = ticket.mozoResponsable;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Propina: $symbol${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            waiter?.nombreCompleto ?? waiter?.name ?? 'Responsable asignado',
          ),
          const Text('Pago separado del total de la venta.'),
          for (final payment in ticket.pagosPropina ?? [])
            Text(
              '${payment.nombre ?? payment.metodoPago?.nombre ?? payment.formaPago ?? "Pago"}: '
              '$symbol${(payment.monto ?? 0).toStringAsFixed(2)}',
            ),
          if (onRemove != null)
            TextButton.icon(
              onPressed: onRemove,
              icon: const Icon(Icons.close),
              label: const Text('Quitar propina'),
            ),
        ],
      ),
    );
  }
}
