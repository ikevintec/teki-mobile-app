import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';
import 'pedidos_ui.dart';

/// Color del estado del pedido, compartido por el listado y el detalle.
Color colorEstadoPedido(BuildContext context, String estado) {
  final colors = Theme.of(context).colorScheme;
  final dark = Theme.of(context).brightness == Brightness.dark;
  return estado == 'Anulado'
      ? colors.error
      : estado == 'Convertido en venta'
      ? (dark ? Colors.green.shade200 : Colors.green.shade800)
      : (dark ? Colors.orange.shade200 : Colors.orange.shade900);
}

/// Misma jerarquía del listado de comprobantes, con estados propios del pedido.
class PedidoListItem extends StatelessWidget {
  final Map<String, dynamic> pedido;
  final VoidCallback onTap;
  const PedidoListItem({super.key, required this.pedido, required this.onTap});

  static const _meses = [
    'ENE',
    'FEB',
    'MAR',
    'ABR',
    'MAY',
    'JUN',
    'JUL',
    'AGO',
    'SET',
    'OCT',
    'NOV',
    'DIC',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final azul = dark ? colors.primary : ColorSchema.primaryColor;
    final secundario = dark ? colors.onSurfaceVariant : Colors.grey.shade700;
    final fecha = DateTime.tryParse('${pedido['fechaEmision'] ?? ''}');
    final total = pedido['totalVenta'] as num?;
    final moneda = '${pedido['codigoMoneda'] ?? 'PEN'}';
    final estado = estadoPedido(pedido);
    final colorEstado = colorEstadoPedido(context, estado);
    final tipoVenta = pedido['tipoVenta'] == 'CONTADO'
        ? 'Al contado'
        : pedido['tipoVenta'] == 'CREDITO'
        ? 'Al crédito'
        : null;
    final cliente = '${pedido['denominacionReceptor'] ?? ''}'.trim();
    return Column(
      children: [
        Semantics(
          button: true,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: LayoutBuilder(
                builder: (context, constraints) => Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: math.max(
                        48,
                        MediaQuery.textScalerOf(context).scale(25) * 1.1,
                      ),
                      decoration: BoxDecoration(
                        color: azul.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: fecha == null
                          ? Icon(
                              Icons.receipt_long_rounded,
                              size: 26,
                              color: azul,
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${fecha.day}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    height: 1.1,
                                    color: azul,
                                  ),
                                ),
                                Text(
                                  _meses[fecha.month - 1],
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.6,
                                    height: 1.1,
                                    color: azul,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pedido',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                          ),
                          Text(
                            '${pedido['serie'] ?? '—'} - ${pedido['numero'] ?? '—'}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cliente.isEmpty ? 'Sin cliente' : cliente,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: secundario,
                            ),
                          ),
                          Text(
                            estado,
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: colorEstado,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth * .36,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            total == null
                                ? 'Sin importe'
                                : '${formatExchange(moneda: moneda)}${total.toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: azul,
                            ),
                          ),
                          if (tipoVenta != null)
                            Text(
                              tipoVenta,
                              textAlign: TextAlign.right,
                              style: GoogleFonts.roboto(
                                fontSize: 11,
                                color: secundario,
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
        ),
        Divider(
          color: dark ? colors.outlineVariant : Colors.grey.shade300,
          height: 1,
        ),
      ],
    );
  }
}
