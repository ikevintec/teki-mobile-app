import 'entrada_numerica_pedido.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';

Future<double?> ingresarPrecio(BuildContext context, {double? actual}) =>
    showDialog<double>(
      context: context,
      builder: (_) => EntradaNumericaPedido(
        titulo: 'Precio manual',
        etiqueta: 'Precio unitario',
        accion: 'Aplicar',
        ayuda: 'Conserva el tipo de precio de la línea.',
        textoInicial: actual?.toStringAsFixed(2),
        permitirCero: true,
      ),
    );

Future<bool> seleccionarPrecioLinea(
  BuildContext context,
  WidgetRef ref,
  int index,
) async {
  final s = ref.read(sesionProvider);
  final l = ref.read(productSaleProvider).productsSales[index];
  if (l.esBonificacion == true || l.producto == null) return false;
  final precios = s.comercial?.precios(l.producto!, s.office?.id) ?? [];
  final manual =
      s.hasPermission('SUPER_USUARIO') ||
      s.hasPermission('VENTAS_EDITAR_PRECIO');
  final elegido = await showModalBottomSheet<Object>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const ListTile(
            title: Text('Precio de esta línea'),
            subtitle: Text('Solo cambia este producto.'),
          ),
          for (final p in precios)
            ListTile(
              title: Text(
                s.comercial?.tipo(p.tipoComercialId)?['nombre'] as String? ??
                    p.tipoPrecio ??
                    'Precio',
              ),
              subtitle: Text(
                '${p.precio?.toStringAsFixed(2)} · ${p.puntoVenta?.nombre ?? 'Compartido'}',
              ),
              leading: Icon(
                p.id == l.productoPrecioId
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              onTap: () => Navigator.pop(ctx, p),
            ),
          if (manual)
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Ingresar precio manual'),
              subtitle: const Text(
                'Se conserva el tipo para reportes y comisiones.',
              ),
              onTap: () => Navigator.pop(ctx, 'manual'),
            ),
        ],
      ),
    ),
  );
  if (elegido == null || !context.mounted) return false;
  if (elegido == 'manual') {
    final n = await ingresarPrecio(
      context,
      actual: ref.read(productSaleProvider).incIgv
          ? l.precioVentaUnitario
          : l.valorUnitario,
    );
    if (n != null && context.mounted) {
      ref.read(productSaleProvider.notifier).setPrecioProductSale(index, n);
      return true;
    }
  } else {
    // El listado proviene del contexto elegible actual; el servidor vuelve a validar al guardar.
    final p = precios.firstWhere((p) => identical(p, elegido));
    ref.read(productSaleProvider.notifier).precioComercial(index, p);
    return true;
  }
  return false;
}
