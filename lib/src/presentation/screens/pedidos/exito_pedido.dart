import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teki_app/src/presentation/widgets/celebration/success_celebration_overlay.dart';

/// Pantalla final al enviar un pedido: check animado + confeti, como la venta.
class ExitoPedido extends StatefulWidget {
  final String numero;
  final String? cliente;
  final String resumen;
  final String total;
  final bool edicion;
  final VoidCallback onNuevo;
  final VoidCallback onVolver;

  const ExitoPedido({
    super.key,
    required this.numero,
    required this.cliente,
    required this.resumen,
    required this.total,
    required this.onNuevo,
    required this.onVolver,
    this.edicion = false,
  });

  @override
  State<ExitoPedido> createState() => _ExitoPedidoState();
}

class _ExitoPedidoState extends State<ExitoPedido> {
  final _check = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colors = tema.colorScheme;
    final texto = tema.textTheme;
    final gris = colors.onSurfaceVariant;
    // Sin AppBar: íconos de la barra de estado legibles sobre el fondo claro.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: tema.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Stack(
        children: [
          Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                      child: Column(
                        children: [
                          AnimatedSuccessCheck(key: _check),
                          const SizedBox(height: 20),
                          Text(
                            widget.edicion
                                ? 'Cambios enviados'
                                : 'Pedido enviado',
                            textAlign: TextAlign.center,
                            style: texto.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.numero,
                            style: texto.titleMedium?.copyWith(
                              color: gris,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.storefront_outlined,
                                        color: gris,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          widget.cliente ?? 'Sin cliente',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: texto.titleMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          widget.resumen,
                                          style: texto.bodyMedium?.copyWith(
                                            color: gris,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Total',
                                            style: texto.bodySmall?.copyWith(
                                              color: gris,
                                            ),
                                          ),
                                          Text(
                                            widget.total,
                                            style: texto.headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: colors.primary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: colors.onPrimaryContainer,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Puedes seguir su estado en Mis pedidos.',
                                    style: texto.bodyMedium?.copyWith(
                                      color: colors.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          icon: const Icon(Icons.add),
                          onPressed: widget.onNuevo,
                          label: const Text('Nuevo pedido'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: widget.onVolver,
                          child: const Text('Volver a mis pedidos'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SuccessCelebrationOverlay(show: true, anchorKey: _check),
        ],
      ),
    );
  }
}
