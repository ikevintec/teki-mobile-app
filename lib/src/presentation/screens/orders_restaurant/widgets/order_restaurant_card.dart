import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/data/models/teki_model/order_restaurant.dart';
import 'package:teki_app/src/presentation/screens/restaurant/widgets/order_options_sheet.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/orders_restaurant/orders_restaurant_provider.dart';
import 'package:teki_app/src/providers/restaurant/restaurant_provider.dart';
import 'package:teki_app/src/utils/notifications.dart';
import 'package:teki_app/src/utils/constants.dart';

class OrderRestaurantCard extends ConsumerWidget {
  final OrderRestaurant order;

  const OrderRestaurantCard({super.key, required this.order});

  bool get _canAnular =>
      order.pagado != true ||
      (order.estado == 'PENDIENTE' && order.tipo == 'LOCAL');

  bool get _canFinalizar {
    final tipo = order.tipo;
    final flagReadyFor = (tipo == 'PEDIDO_LOCAL' ||
            tipo == 'PEDIDO_FORANEO' ||
            tipo == 'PEDIDO_LOCAL_INTERNO') ||
        (tipo == 'PEDIDO_ONLINE' && order.estadoOnline == 'ACEPTADO');
    return flagReadyFor &&
        order.pagado == true &&
        order.estado != 'FINALIZADO' &&
        order.estado != 'CANCELADO' &&
        order.esBorrador != true;
  }

  Future<void> _finalizarOrden(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalizar pedido'),
        content: const Text('¿Estás seguro de finalizar el pedido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sí'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final pvId = ref.read(sesionProvider).office?.id;
    if (pvId == null) {
      errorNotification('No se pudo obtener el punto de venta');
      return;
    }
    await ref.read(restaurantProvider.notifier).updateOrderStatus(
          order.id!,
          'FINALIZADO',
          pvId,
          updateInventory: false,
        );
    ref.read(ordersRestaurantProvider.notifier).refresh();
  }

  Future<void> _anularOrden(BuildContext context, WidgetRef ref) async {
    if (!ref.read(sesionProvider).hasPermission('RESTAURANTE_PEDIDOS_ANULAR')) {
      warningNotification('No tienes permiso para anular órdenes');
      return;
    }
    final result = await showDialog<({bool confirmed, bool updateInventory, String observacion})>(
      context: context,
      builder: (_) => const AnularOrdenDialog(),
    );
    if (result == null || !result.confirmed) return;
    final pvId = ref.read(sesionProvider).office?.id;
    final notifier = ref.read(restaurantProvider.notifier);
    Get.back();
    if (pvId != null) {
      notifier.updateOrderStatus(
        order.id!,
        'CANCELADO',
        pvId,
        updateInventory: result.updateInventory,
        observacion: result.observacion.isNotEmpty ? result.observacion : null,
      );
    }
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: Colors.grey.shade200),
              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: ColorSchema.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_outlined,
                      color: ColorSchema.primaryColor, size: 20),
                ),
                title: const Text(
                  'Ver detalle',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  showOrderDetailDialog(context, order);
                },
              ),
              if (_canFinalizar)
                ListTile(
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.check_circle_outline,
                        color: Colors.green, size: 20),
                  ),
                  title: const Text(
                    'Finalizar pedido',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.green),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _finalizarOrden(context, ref);
                  },
                ),
              if (_canAnular &&
                  ref
                      .read(sesionProvider)
                      .hasPermission('RESTAURANTE_PEDIDOS_ANULAR'))
                ListTile(
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.cancel_outlined,
                        color: Colors.red, size: 20),
                  ),
                  title: const Text(
                    'Anular orden',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _anularOrden(context, ref);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showOptions(context, ref),
      child: Card(
      elevation: 0.5,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildOrderNumber(),
                const Spacer(),
                _buildEstadoBadge(),
                // Pista de que la card abre acciones al tocar.
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.receipt_long_outlined,
                  label: _comandaLabel(),
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.table_restaurant_outlined,
                  label: _mesaLabel(),
                ),
                const SizedBox(width: 8),
                _buildTipoBadge(),
              ],
            ),
            if (order.nombreCliente != null &&
                order.nombreCliente!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 14, color: ColorSchema.subTitleTextColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.nombreCliente!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ColorSchema.subTitleTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            // ── Antigüedad (con urgencia) + total del pedido ──────────────
            const SizedBox(height: 8),
            Row(
              children: [
                if (order.fecha != null) ...[
                  Icon(Icons.schedule_rounded,
                      size: 13, color: _antiguedadColor()),
                  const SizedBox(width: 4),
                  Text(
                    _antiguedadLabel(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: _esUrgente()
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: _antiguedadColor(),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  'S/. ${_totalPedido().toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ColorSchema.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// Total del pedido: items no cancelados de todas las comandas
  /// (misma fórmula que el detalle de orden).
  double _totalPedido() {
    var total = 0.0;
    for (final c in (order.comandas ?? [])) {
      for (final item in (c.items ?? [])) {
        final cancelado = item.eliminado == true ||
            item.estadoComandaDetalle?.toUpperCase() == 'CANCELADO';
        if (cancelado) continue;
        total += (item.precioVenta ?? 0.0) * (item.cantidad ?? 1.0);
      }
    }
    return total;
  }

  int get _minutos => order.fecha == null
      ? 0
      : DateTime.now().difference(order.fecha!).inMinutes;

  /// Un pedido activo con más de 45 min merece atención.
  bool _esUrgente() =>
      _minutos >= 45 &&
      order.estado != 'FINALIZADO' &&
      order.estado != 'CANCELADO';

  String _antiguedadLabel() {
    final m = _minutos;
    if (m < 1) return 'recién';
    if (m < 60) return 'hace $m min';
    final h = m ~/ 60;
    return 'hace ${h}h ${(m % 60).toString().padLeft(2, '0')}m';
  }

  Color _antiguedadColor() {
    if (order.estado == 'FINALIZADO' || order.estado == 'CANCELADO') {
      return Colors.grey.shade500;
    }
    final m = _minutos;
    if (m >= 90) return const Color(0xFFC62828);
    if (m >= 45) return const Color(0xFFE65100);
    return Colors.grey.shade500;
  }

  Widget _buildOrderNumber() {
    return Text(
      'Orden #${order.numeroOrden ?? order.id ?? '-'}',
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: ColorSchema.titleTextColor,
      ),
    );
  }

  Widget _buildEstadoBadge() {
    final config = _estadoConfig(order.estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: config.$1.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.$1.withValues(alpha: 0.4)),
      ),
      child: Text(
        config.$2,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: config.$1,
        ),
      ),
    );
  }

  Widget _buildTipoBadge() {
    final label = _tipoLabel(order.tipo);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ColorSchema.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: ColorSchema.primaryColor,
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: ColorSchema.subTitleTextColor),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: ColorSchema.subTitleTextColor,
          ),
        ),
      ],
    );
  }

  String _comandaLabel() {
    final numero = order.comandas?.isNotEmpty == true
        ? order.comandas!.first.numeroComanda
        : null;
    return numero != null ? 'Comanda #$numero' : 'Sin comanda';
  }

  String _mesaLabel() {
    final numero = order.mesa?.numero?.toString();
    return numero != null ? 'Mesa $numero' : 'Sin mesa';
  }

  String _tipoLabel(String? tipo) {
    switch (tipo) {
      case 'LOCAL':
        return 'Mesa';
      case 'PEDIDO_LOCAL_INTERNO':
        return 'Interno';
      case 'PEDIDO_LOCAL':
        return 'Para llevar';
      case 'PEDIDO_FORANEO':
        return 'Delivery';
      case 'PEDIDO_ONLINE':
        return 'Online';
      default:
        return tipo ?? '-';
    }
  }

  (Color, String) _estadoConfig(String? estado) {
    switch (estado) {
      case 'PENDIENTE':
        return (Colors.orange, 'Pendiente');
      case 'PREPARADO':
        return (Colors.blue, 'Preparado');
      case 'PRECUENTA':
        return (Colors.purple, 'Pre-cuenta');
      case 'FINALIZADO':
        return (Colors.green, 'Finalizado');
      case 'CANCELADO':
        return (Colors.red, 'Cancelado');
      default:
        return (Colors.grey, estado ?? '-');
    }
  }
}
