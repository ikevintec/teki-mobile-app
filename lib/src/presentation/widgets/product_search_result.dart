import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';
import 'package:teki_app/src/data/models/teki_model/ticket_detail.dart';
import 'package:teki_app/src/domain/distribuidor/contexto_comercial.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/presentation/screens/pedidos/busqueda_pedido.dart';
import 'package:teki_app/src/presentation/screens/pedidos/entrada_numerica_pedido.dart';

class ProductSearchResult extends ConsumerWidget {
  final Product product;
  final bool agregando;
  final (String, String?)? precioStock;
  final String? promocion, subtitulo;
  final VoidCallback? onAdd, onDecrease, onEdit, onRemove;
  const ProductSearchResult({
    super.key,
    required this.product,
    this.agregando = false,
    this.precioStock,
    this.promocion,
    this.subtitulo,
    this.onAdd,
    this.onDecrease,
    this.onEdit,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider);
    final puntoVenta = sesion.office;
    final base = sesion.comercial ?? const ContextoComercial();
    final cabecera = base.activo
        ? ref.watch(
                ticketProvider.select((s) => s.ticket.tipoPrecioCabeceraId),
              ) ??
              base.cabecera
        : null;
    final comercial = base.conCabecera(cabecera);
    final precio = comercial.activo
        ? comercial.elegir(product, puntoVenta?.id, 1)?.precio
        : comercial
              .precios(product, puntoVenta?.id)
              .where((p) => p.tipoPrecio == 'POR_DEFECTO')
              .firstOrNull
              ?.precio;
    final stock =
        product.inventarios
            ?.firstWhere(
              (inv) => inv.puntoVenta?.id == puntoVenta?.id,
              orElse: () => Inventory(stock: 0.0),
            )
            .stock ??
        0.0;
    final lineas = ref
        .watch(productSaleProvider)
        .productsSales
        .where((l) => l.producto?.id == product.id && l.esBonificacion != true)
        .toList();
    final enVenta = lineas.fold<double>(
      0,
      (total, l) => total + (l.cantidad ?? 0),
    );
    final editable = lineas.any((l) => l.comandaDetalle == null);
    final inicial = (product.nombre?.isNotEmpty == true)
        ? product.nombre![0].toUpperCase()
        : 'P';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: agregando ? null : onAdd,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ColorSchema.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    inicial,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ColorSchema.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (product.nombre ?? '').trim(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: ColorSchema.primaryColor.withValues(
                                alpha: 0.09,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              precioStock?.$1 ??
                                  (precio == null
                                      ? 'Sin precio'
                                      : '${product.moneda ?? ''} ${precio.toStringAsFixed(2)}'),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: ColorSchema.primaryColor,
                              ),
                            ),
                          ),
                          if (precioStock == null ||
                              precioStock!.$2 != null) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 12,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              precioStock?.$2 ??
                                  'Stock ${cantidadPedido(stock)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (subtitulo?.isNotEmpty == true)
                        Text(
                          subtitulo!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      if (promocion != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.card_giftcard,
                                size: 14,
                                color: ColorSchema.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  promocion!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: ColorSchema.primaryColor,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (enVenta == 0 && !agregando)
                  IconButton(
                    tooltip: 'Agregar ${product.nombre ?? 'producto'}',
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_circle_outline),
                    color: ColorSchema.primaryColor,
                  ),
              ],
            ),
          ),
          if (agregando)
            const Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ColorSchema.primaryColor,
                ),
              ),
            )
          else if (enVenta > 0)
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Disminuir ${product.nombre ?? 'producto'}',
                  onPressed: editable ? onDecrease : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: ColorSchema.primaryColor,
                ),
                Tooltip(
                  message:
                      'Cambiar cantidad de ${product.nombre ?? 'producto'}',
                  child: TextButton(
                    onPressed: editable ? onEdit : null,
                    child: Text(cantidadPedido(enVenta)),
                  ),
                ),
                IconButton(
                  tooltip: 'Agregar ${product.nombre ?? 'producto'}',
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_circle_outline),
                  color: ColorSchema.primaryColor,
                ),
                IconButton(
                  tooltip: 'Quitar ${product.nombre ?? 'producto'}',
                  onPressed: editable ? onRemove : null,
                  icon: const Icon(Icons.delete_outline),
                  color: ColorSchema.primaryColor,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

Future<(TicketDetail, double)?> editarCantidadResultado(
  BuildContext context,
  Product producto,
  List<TicketDetail> lineas,
) async {
  bool editable(TicketDetail linea) =>
      linea.comandaDetalle == null && linea.esBonificacion != true;
  TicketDetail? linea;
  if (lineas.isEmpty) return null;
  if (lineas.length == 1) {
    linea = lineas.single;
  } else {
    linea = await showDialog<TicketDetail>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Líneas de ${producto.nombre ?? 'producto'}'),
        children: [
          for (var i = 0; i < lineas.length; i++)
            SimpleDialogOption(
              onPressed: editable(lineas[i])
                  ? () => Navigator.pop(context, lineas[i])
                  : null,
              child: Text(
                'Línea ${i + 1}: ${cantidadPedido(lineas[i].cantidad)} × '
                '${(lineas[i].precioVentaUnitario ?? 0).toStringAsFixed(2)}'
                '${lineas[i].producto?.envaseRetornable == true ? (lineas[i].prestamoEnvase == true
                          ? ' · Envase prestado'
                          : lineas[i].devolvioEnvase == true
                          ? ' · Con canje'
                          : ' · Sin canje') : ''}'
                '${editable(lineas[i]) ? '' : ' · Comanda (no editable)'}',
              ),
            ),
        ],
      ),
    );
  }
  if (!context.mounted || linea == null || !editable(linea)) return null;
  final valor = await showDialog<double>(
    context: context,
    builder: (_) => EntradaNumericaPedido(
      titulo: 'Cantidad',
      etiqueta: 'Cantidad mayor a cero',
      accion: 'Aceptar',
      textoInicial: cantidadPedido(linea!.cantidad),
    ),
  );
  return valor == null ? null : (linea, valor);
}
