import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail.dart';
import 'package:teki_app/src/data/models/teki_model/order_restaurant.dart';
import 'package:teki_app/src/presentation/screens/restaurant/widgets/comanda_detail_item_tile.dart';
import 'package:teki_app/src/presentation/screens/restaurant/widgets/order_options/action_tile.dart';
import 'package:teki_app/src/presentation/screens/restaurant/widgets/order_options/anular_orden_dialog.dart';
import 'package:teki_app/src/presentation/screens/restaurant/widgets/order_options/order_detail_dialog.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/restaurant/restaurant_provider.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/shared/services/command_print_service.dart';
import 'package:teki_app/src/utils/constants.dart';

// Re-exports para consumidores existentes (restaurant_mesas_screen, order_restaurant_card)
export 'package:teki_app/src/presentation/screens/restaurant/widgets/order_options/anular_orden_dialog.dart' show AnularOrdenDialog;
export 'package:teki_app/src/presentation/screens/restaurant/widgets/order_options/order_detail_dialog.dart' show showOrderDetailDialog;

class OrderOptionsSheet extends ConsumerStatefulWidget {
  final OrderRestaurant order;

  const OrderOptionsSheet({super.key, required this.order});

  static Future<void> show(BuildContext context, OrderRestaurant order) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => OrderOptionsSheet(order: order),
    );
  }

  @override
  ConsumerState<OrderOptionsSheet> createState() => _OrderOptionsSheetState();
}

class _OrderOptionsSheetState extends ConsumerState<OrderOptionsSheet> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final estado = order.estado;
    final isPendiente = estado == 'PENDIENTE';
    final hasItemPreparado = isPendiente &&
        (order.comandas ?? []).any(
          (c) => (c.items ?? []).any(
            (item) =>
                item.estadoComandaDetalle?.toUpperCase() == 'PREPARADO' &&
                item.eliminado != true,
          ),
        );
    final hasSinCuenta = (order.comandas ?? []).any(
      (c) => (c.items ?? []).any(
        (item) =>
            item.cuenta == null &&
            item.estadoComandaDetalle?.toUpperCase() != 'CANCELADO',
      ),
    );

    final allItems = _getAllItems(order);
    final total = allItems.fold<double>(
      0.0,
      (sum, d) => sum + ((d.precioVenta ?? 0.0) * (d.cantidad ?? 1.0)),
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ColorSchema.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.table_restaurant, color: ColorSchema.primaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mesa ${order.mesa?.numero ?? order.mesa?.id ?? '-'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        '${allItems.length} producto(s) · S/. ${total.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: hasItemPreparado
                        ? const Color(0xFFE65100).withValues(alpha: 0.12)
                        : isPendiente
                            ? const Color(0xFF1565C0).withValues(alpha: 0.12)
                            : const Color(0xFF2E7D32).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    hasItemPreparado ? 'PREPARADO' : (estado ?? ''),
                    style: TextStyle(
                      color: hasItemPreparado
                          ? const Color(0xFFE65100)
                          : isPendiente
                              ? const Color(0xFF1565C0)
                              : const Color(0xFF2E7D32),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(color: ColorSchema.primaryColor)),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Column(
                children: [
                  ActionTile(
                    icon: Icons.list_alt_rounded,
                    label: 'Ver detalle',
                    subtitle: 'Comandas y cuentas de la orden',
                    color: ColorSchema.primaryColor,
                    onTap: () => _showDetailDialog(context, order),
                  ),
                  if (isPendiente) ...[
                    ActionTile(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Agregar comanda adicional',
                      subtitle: 'Enviar nuevos productos a esta mesa',
                      color: ColorSchema.primaryColor,
                      onTap: () {
                        final pvId = ref.read(sesionProvider).office?.id;
                        final notifier = ref.read(restaurantProvider.notifier);
                        Navigator.of(context).pop();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Get.toNamed(
                            AppRoutes.restaurantComanda,
                            arguments: {
                              'table': order.mesa,
                              'existingOrderId': order.id,
                            },
                          )?.then((_) {
                            if (pvId != null) notifier.reload(pvId);
                          });
                        });
                      },
                    ),
                  ],
                  if (isPendiente || (estado == 'PRECUENTA' && hasSinCuenta)) ...[
                    ActionTile(
                      icon: Icons.call_split_rounded,
                      label: 'Dividir cuenta',
                      subtitle: 'Asignar productos a cuentas separadas',
                      color: ColorSchema.primaryColor,
                      onTap: () {
                        final pvId = ref.read(sesionProvider).office?.id;
                        final notifier = ref.read(restaurantProvider.notifier);
                        Navigator.of(context).pop();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Get.toNamed(AppRoutes.restaurantDividir, arguments: {'order': order})
                              ?.then((_) {
                                if (pvId != null) notifier.reload(pvId);
                              });
                        });
                      },
                    ),
                    ActionTile(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Finalizar cuenta',
                      subtitle: 'Generar una cuenta única para la orden',
                      color: Colors.green,
                      onTap: () => _finalizarCuenta(context, order),
                    ),
                    ActionTile(
                      icon: Icons.cancel_outlined,
                      label: 'Anular orden',
                      subtitle: 'Cancelar todos los productos de la mesa',
                      color: Colors.red,
                      onTap: () => _anularOrden(context, order),
                      isLast: true,
                    ),
                  ] else ...[
                    ActionTile(
                      icon: Icons.delete_outline_rounded,
                      label: 'Eliminar precuentas',
                      subtitle: 'La orden volverá a estado PENDIENTE',
                      color: Colors.orange,
                      onTap: () => _eliminarPrecuentas(context, order),
                    ),
                    ActionTile(
                      icon: Icons.cancel_outlined,
                      label: 'Anular orden',
                      subtitle: 'Cancelar todos los productos de la mesa',
                      color: Colors.red,
                      onTap: () => _anularOrden(context, order),
                      isLast: true,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<CommandDetail> _getAllItems(OrderRestaurant order) {
    final List<CommandDetail> items = [];
    for (final comanda in (order.comandas ?? [])) {
      items.addAll(
        (comanda.items ?? []).where((i) => !ComandaDetailStatus.isCancelledItem(i)),
      );
    }
    return items;
  }

  void _showDetailDialog(BuildContext context, OrderRestaurant order) {
    showOrderDetailDialog(context, order);
  }

  Future<void> _finalizarCuenta(BuildContext context, OrderRestaurant order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Finalizar cuenta',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(dialogCtx, false),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.green.shade400, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '¿Desea generar una cuenta única para esta orden? Se registrará como una sola cuenta.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogCtx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogCtx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    final pvId = ref.read(sesionProvider).office?.id;
    final notifier = ref.read(restaurantProvider.notifier);
    setState(() => _isLoading = true);
    final ok = await notifier.finalizarCuenta(order.id!, pvId);
    if (ok) {
      Get.back();
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarPrecuentas(BuildContext context, OrderRestaurant order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Eliminar precuentas',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(dialogCtx, false),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade100),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade400, size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            '¿Desea eliminar las precuentas? La orden volverá al estado PENDIENTE.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogCtx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogCtx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    final pvId = ref.read(sesionProvider).office?.id;
    final notifier = ref.read(restaurantProvider.notifier);
    Get.back();
    if (pvId != null) {
      notifier.deleteOrderChecks(order.id!, pvId);
    }
  }

  Future<void> _anularOrden(BuildContext context, OrderRestaurant order) async {
    final result = await showDialog<({bool confirmed, bool updateInventory, String observacion})>(
      context: context,
      builder: (_) => const AnularOrdenDialog(),
    );
    if (result == null || !result.confirmed) return;
    final sesion = ref.read(sesionProvider);
    final pvId = sesion.office?.id;
    final notifier = ref.read(restaurantProvider.notifier);
    Get.back();
    if (pvId != null) {
      final changeItems = await notifier.updateOrderStatus(
        order.id!,
        'CANCELADO',
        pvId,
        updateInventory: result.updateInventory,
        observacion: result.observacion.isNotEmpty ? result.observacion : null,
      );

      final office = sesion.office;
      if (office?.id != null && changeItems.isNotEmpty) {
        CommandPrintService().printCancellation(
          changeItems: changeItems,
          puntoVenta: office!,
          escPos: sesion.config?.imprimeTicketsEscPos ?? false,
          clientPrinter: sesion.config?.clienteImpresion,
          idCompany: sesion.company?.id,
        );
      }
    }
  }

}
