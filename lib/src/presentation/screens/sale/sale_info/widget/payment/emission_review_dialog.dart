import 'package:get/get.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';

/// La coincidencia se confirma por el usuario: el servidor asigna el correlativo.
class EmissionReviewDialog extends StatefulWidget {
  final TicketNotifier notifier;
  const EmissionReviewDialog({super.key, required this.notifier});

  @override
  State<EmissionReviewDialog> createState() => _EmissionReviewDialogState();
}

class _EmissionReviewDialogState extends State<EmissionReviewDialog> {
  late Future<List<Ticket>> _result;

  @override
  void initState() {
    super.initState();
    _result = widget.notifier.verifyPendingEmission();
  }

  Future<void> _confirmNotRegistered() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Confirmaste que la venta no se registró?'),
        content: const Text(
          'Una respuesta perdida no significa que la venta falló. '
          'Continúa solo después de revisar los comprobantes para evitar cobrar dos veces.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Seguir revisando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmo que no se registró'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    widget.notifier.confirmEmissionNotRegistered();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Verificar emisión'),
    content: SizedBox(
      width: double.maxFinite,
      child: FutureBuilder<List<Ticket>>(
        future: _result,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Consultando comprobantes…'),
              ],
            );
          }
          if (snapshot.hasError) {
            return const Text(
              'No pudimos consultar el resultado. Revisa tu conexión y vuelve a verificar.',
            );
          }
          final tickets = snapshot.data ?? [];
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'La emisión quedó sin confirmar. Estos son los últimos comprobantes de la serie. '
                  'Revisa el cliente, importe y fecha. Selecciona únicamente el que corresponde a esta venta.',
                ),
                if (tickets.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      'No aparecen comprobantes. La operación podría seguir procesándose; vuelve a verificar.',
                    ),
                  ),
                for (final ticket in tickets)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${ticket.serie ?? ''}-${ticket.numero ?? ''} · '
                      '${ticket.codigoMoneda ?? ''} ${(ticket.totalVenta ?? 0).toStringAsFixed(2)}',
                    ),
                    subtitle: Text(
                      '${ticket.denominacionReceptor ?? ''}\n${ticket.fechaEmision ?? ''}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text(
                            '¿Este comprobante corresponde a la venta?',
                          ),
                          content: Text(
                            '${ticket.identificadorDocumento ?? '${ticket.serie}-${ticket.numero}'}\n'
                            '${ticket.denominacionReceptor ?? ''}\n'
                            '${ticket.codigoMoneda ?? ''} ${(ticket.totalVenta ?? 0).toStringAsFixed(2)}',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Volver'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Sí, abrir comprobante'),
                            ),
                          ],
                        ),
                      );
                      if (mounted && confirm == true) {
                        Navigator.pop(this.context, ticket);
                      }
                    },
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Si no encuentras la venta aquí, revisa también la lista completa de comprobantes. '
                  'Una lista vacía no confirma que la emisión haya fallado.',
                ),
                TextButton(
                  onPressed: () async {
                    await Get.toNamed(AppRoutes.comprobantesVer);
                    if (mounted) {
                      setState(
                        () => _result = widget.notifier.verifyPendingEmission(),
                      );
                    }
                  },
                  child: const Text('Ver lista completa de comprobantes'),
                ),
                TextButton(
                  onPressed: _confirmNotRegistered,
                  child: const Text('Ya revisé y confirmé que no se registró'),
                ),
              ],
            ),
          );
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Volver sin emitir'),
      ),
      TextButton(
        onPressed: () =>
            setState(() => _result = widget.notifier.verifyPendingEmission()),
        child: const Text('Volver a verificar'),
      ),
    ],
  );
}
