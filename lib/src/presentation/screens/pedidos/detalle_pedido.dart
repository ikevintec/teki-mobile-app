import 'package:flutter/material.dart';
import 'package:teki_app/src/utils/formats.dart';
import 'busqueda_pedido.dart' show cantidadPedido;
import 'pedido_list_item.dart' show colorEstadoPedido;
import 'pedidos_ui.dart';

/// Detalle de solo lectura de un pedido que ya no se puede editar
/// (convertido en venta, anulado, en atención...).
class DetallePedido extends StatelessWidget {
  final Map<String, dynamic> pedido;
  const DetallePedido({super.key, required this.pedido});

  static const _unidades = {
    'NIU': 'und',
    'ZZ': 'und',
    'EA': 'und',
    'KGM': 'kg',
    'GRM': 'g',
    'LTR': 'L',
    'MTR': 'm',
    'BX': 'caja',
    'PK': 'paq',
    'DZN': 'doc',
  };

  /// Solo para mostrar: 2 decimales, o hasta 4 si el precio los tiene.
  static String _precio(num? v) {
    final s = (v ?? 0).toStringAsFixed(4);
    return s.endsWith('00')
        ? s.substring(0, s.length - 2)
        : s.replaceFirst(RegExp(r'0$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colors = tema.colorScheme;
    final texto = tema.textTheme;
    final gris = colors.onSurfaceVariant;
    final simbolo = formatExchange(
      moneda: '${pedido['codigoMoneda'] ?? 'PEN'}',
    );
    final estado = estadoPedido(pedido);
    final colorEstado = colorEstadoPedido(context, estado);
    final fecha = DateTime.tryParse('${pedido['fechaEmision'] ?? ''}');
    final cliente = '${pedido['denominacionReceptor'] ?? ''}'.trim();
    final atiende = '${pedido['responsablePedidoNombre'] ?? ''}'.trim();
    final items = (pedido['items'] as List? ?? const []).cast<Map>();
    final venta = pedido['comprobanteRelacionado'] as Map?;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pedido ${pedido['serie'] ?? '—'}-${pedido['numero'] ?? '—'}',
                        style: texto.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (fecha != null)
                        Text(
                          '${fecha.day.toString().padLeft(2, '0')}/'
                          '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}',
                          style: texto.bodySmall?.copyWith(color: gris),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorEstado.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    estado,
                    style: texto.labelMedium?.copyWith(
                      color: colorEstado,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: Text(
                  cliente.isEmpty ? 'Sin cliente' : cliente,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: atiende.isEmpty
                    ? null
                    : Text(
                        'Atiende: $atiende',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${items.length} ${items.length == 1 ? 'producto' : 'productos'}',
              style: texto.titleSmall?.copyWith(color: gris),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final l = items[i];
                  final regalo = l['esBonificacion'] == true;
                  final cantidad = (l['cantidad'] as num?)?.toDouble();
                  final unidad =
                      _unidades[l['codigoUnidadMedida']] ??
                      '${l['codigoUnidadMedida'] ?? ''}';
                  final unitario = l['precioVentaUnitario'] as num?;
                  final totalLinea =
                      (l['precioTotal'] as num?) ??
                      (cantidad ?? 0) * (unitario ?? 0);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        if (regalo) ...[
                          Icon(
                            Icons.card_giftcard,
                            size: 20,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${l['descripcion'] ?? ''}',
                                style: texto.bodyLarge,
                              ),
                              Text(
                                regalo
                                    ? '${cantidadPedido(cantidad)} $unidad de regalo'
                                    : '${cantidadPedido(cantidad)} $unidad × $simbolo${_precio(unitario)}',
                                style: texto.bodySmall?.copyWith(color: gris),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          regalo
                              ? 'Gratis'
                              : '$simbolo${totalLinea.toStringAsFixed(2)}',
                          style: texto.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: regalo ? colors.primary : null,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(child: Text('Total', style: texto.titleMedium)),
                  Text(
                    '$simbolo${((pedido['totalVenta'] as num?) ?? 0).toStringAsFixed(2)}',
                    style: texto.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (venta != null)
              Card(
                margin: EdgeInsets.zero,
                color: colors.primaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.receipt_long_outlined,
                    color: colors.onPrimaryContainer,
                  ),
                  title: Text(
                    'Venta ${venta['serie']}-${venta['numero']}',
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle:
                      (venta['estadoComprobante'] ?? '').toString().isEmpty
                      ? null
                      : Text(
                          _capitalizar('${venta['estadoComprobante']}'),
                          style: TextStyle(color: colors.onPrimaryContainer),
                        ),
                ),
              ),
            const SizedBox(height: 16),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  static String _capitalizar(String s) => s.isEmpty
      ? s
      : s[0].toUpperCase() + s.substring(1).toLowerCase().replaceAll('_', ' ');
}
