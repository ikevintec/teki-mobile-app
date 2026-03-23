import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/data/models/teki_model/check.dart';
import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/commandDetail.dart';
import 'package:teki_app/src/data/models/teki_model/cutomer.dart';
import 'package:teki_app/src/data/models/teki_model/delivery.dart';
import 'package:teki_app/src/data/models/teki_model/orderRestaurant.dart';
import 'package:teki_app/src/presentation/screens/restaurant/widgets/comanda_detail_item_tile.dart';
import 'package:teki_app/src/presentation/screens/restaurant/widgets/item_action_bottom_sheet.dart';
import 'package:teki_app/src/data/repositories/restaurant_repository_impl.dart';
import 'package:teki_app/src/presentation/screens/sale/products/products_sale_screen.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/restaurant/restaurant_provider.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/formats.dart';
import 'package:teki_app/src/utils/notifications.dart';

void showOrderDetailDialog(BuildContext context, OrderRestaurant order) {
  showDialog(
    context: context,
    builder: (_) => _OrderDetailDialog(order: order),
  );
}

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
                  _ActionTile(
                    icon: Icons.list_alt_rounded,
                    label: 'Ver detalle',
                    subtitle: 'Comandas y cuentas de la orden',
                    color: ColorSchema.primaryColor,
                    onTap: () => _showDetailDialog(context, order),
                  ),
                  if (isPendiente) ...[
                    _ActionTile(
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
                    _ActionTile(
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
                    _ActionTile(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Finalizar cuenta',
                      subtitle: 'Generar una cuenta única para la orden',
                      color: Colors.green,
                      onTap: () => _finalizarCuenta(context, order),
                    ),
                    _ActionTile(
                      icon: Icons.cancel_outlined,
                      label: 'Anular orden',
                      subtitle: 'Cancelar todos los productos de la mesa',
                      color: Colors.red,
                      onTap: () => _anularOrden(context, order),
                      isLast: true,
                    ),
                  ] else ...[
                    _ActionTile(
                      icon: Icons.delete_outline_rounded,
                      label: 'Eliminar precuentas',
                      subtitle: 'La orden volverá a estado PENDIENTE',
                      color: Colors.orange,
                      onTap: () => _eliminarPrecuentas(context, order),
                    ),
                    _ActionTile(
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
    try {
      final repo = RestaurantRepositoryImpl();
      await repo.saveChecks(order.id!, [Check(items: [])]);
      Get.back();
      successNotification('Cuenta finalizada');
      if (pvId != null) notifier.reload(pvId);
    } catch (e) {
      setState(() => _isLoading = false);
      errorNotification(e.toString());
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

}

class AnularOrdenDialog extends StatefulWidget {
  const AnularOrdenDialog();

  @override
  State<AnularOrdenDialog> createState() => _AnularOrdenDialogState();
}

class _AnularOrdenDialogState extends State<AnularOrdenDialog> {
  final _observacionController = TextEditingController();
  bool _updateInventory = true;

  @override
  void dispose() {
    _observacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
              color: Colors.red,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cancel_outlined, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Anular orden',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.red.shade400, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '¿Está seguro de anular esta orden?',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Observación',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _observacionController,
                  decoration: InputDecoration(
                    hintText: 'Ingrese una observación (opcional)',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: ColorSchema.primaryColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => setState(() => _updateInventory = !_updateInventory),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _updateInventory
                          ? ColorSchema.primaryColor.withValues(alpha: 0.06)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _updateInventory
                            ? ColorSchema.primaryColor.withValues(alpha: 0.3)
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _updateInventory,
                            activeColor: ColorSchema.primaryColor,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            onChanged: (v) => setState(() => _updateInventory = v ?? true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Descontar inventario',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
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
                    onPressed: () => Navigator.pop(context),
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
                    onPressed: () => Navigator.pop(
                      context,
                      (confirmed: true, updateInventory: _updateInventory, observacion: _observacionController.text),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('Anular', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isLast;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade300, size: 20),
              ],
            ),
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey.shade100),
      ],
    );
  }
}

class _OrderDetailDialog extends ConsumerStatefulWidget {
  final OrderRestaurant order;

  const _OrderDetailDialog({required this.order});

  @override
  ConsumerState<_OrderDetailDialog> createState() => _OrderDetailDialogState();
}

class _OrderDetailDialogState extends ConsumerState<_OrderDetailDialog>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late TabController _tabController;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final fecha = widget.order.fecha;
    if (fecha != null) {
      _elapsed = DateTime.now().difference(fecha);
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          final fecha = widget.order.fecha;
          _elapsed = fecha != null ? DateTime.now().difference(fecha) : Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _tabController.dispose();
    super.dispose();
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '${h}h ${m}m ${s}s';
    return '${m}m ${s}s';
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '-';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day/$month ${dt.year} $hour:$min';
  }

  /// Agrupa los items de las comandas por cuenta (cuenta.id).
  Map<int, List<CommandDetail>> _buildCuentasItemsMap(OrderRestaurant order) {
    final map = <int, List<CommandDetail>>{};
    for (final comanda in (order.comandas ?? [])) {
      for (final item in (comanda.items ?? [])) {
        final cuentaId = item.cuenta?.id;
        if (cuentaId != null) {
          map.putIfAbsent(cuentaId, () => []).add(item);
        }
      }
    }
    return map;
  }


  Widget _buildSubtotalRow(double subtotal) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Subtotal: S/. ${subtotal.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdenView(OrderRestaurant order, bool hasItemPreparado, bool isPendiente) {
    final estadoColor = hasItemPreparado
        ? const Color(0xFFE65100)
        : isPendiente
            ? const Color(0xFF1565C0)
            : const Color(0xFF2E7D32);
    final estadoLabel = hasItemPreparado ? 'PREPARADO' : (order.estado ?? '-');
    final isDelivery = order.tipo == 'DELIVERY';
    final isPedidoOnline = order.tipo == 'PEDIDO_ONLINE';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Información General
          _LabeledInfoCard(
            title: 'Información General',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: estadoColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                estadoLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            children: [
              _OrderInfoRow(
                icon: Icons.access_time_rounded,
                label: 'Tiempo en mesa',
                value: _formatElapsed(_elapsed),
              ),
              if ((order.mesa?.numero ?? order.mesa?.id) != null)
                _OrderInfoRow(
                  icon: Icons.table_restaurant_rounded,
                  label: 'Mesa',
                  value: 'Mesa ${order.mesa?.numero ?? order.mesa?.id}',
                ),
              if (order.tipo?.isNotEmpty == true)
                _OrderInfoRow(
                  icon: Icons.local_dining_rounded,
                  label: 'Tipo',
                  value: normalizeEnumLabel(order.tipo),
                ),
              if (order.numeroComensales != null)
                _OrderInfoRow(
                  icon: Icons.people_alt_rounded,
                  label: 'Comensales',
                  value: '${order.numeroComensales}',
                ),
              if ((order.usuario?.nombreCompleto ?? order.usuario?.name)?.isNotEmpty == true)
                _OrderInfoRow(
                  icon: Icons.person_rounded,
                  label: 'Atendido por',
                  value: order.usuario!.nombreCompleto ?? order.usuario!.name!,
                ),
              if (order.fecha != null)
                _OrderInfoRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Apertura',
                  value: _formatDateTime(order.fecha),
                ),
            ],
          ),
          // Cliente (solo DELIVERY)
          if (isDelivery) _ClienteInfoCard(cliente: order.cliente),
          // Dirección (si hay data)
          _DireccionInfoCard(
            direccionCompleta: order.direccionCompleta,
            referencia: order.referencia,
            montoDelivery: order.montoDelivery,
          ),
          // Información Online (solo PEDIDO_ONLINE)
          if (isPedidoOnline)
            _OnlineInfoCard(
              estadoOnline: order.estadoOnline,
              formaPago: order.formaPago,
              nombreFormaPago: order.nombreFormaPago,
              envio: order.envio,
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildComandasView(List<Command> comandas) {
    if (comandas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Sin comandas', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: comandas.length,
      itemBuilder: (context, index) {
        final comanda = comandas[index];
        const statusOrder = {'PREPARADO': 0, 'PENDIENTE': 1, 'DESPACHADO': 2, 'CANCELADO': 3};
        final items = <CommandDetail>[...(comanda.items ?? [])]..sort((a, b) {
            final aO = statusOrder[a.estadoComandaDetalle?.toUpperCase()] ?? 1;
            final bO = statusOrder[b.estadoComandaDetalle?.toUpperCase()] ?? 1;
            return aO.compareTo(bO);
          });
        final subtotal = items.fold<double>(
          0.0,
          (s, i) => ComandaDetailStatus.isCancelledItem(i)
              ? s
              : s + ((i.precioVenta ?? 0.0) * (i.cantidad ?? 1.0)),
        );
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ColorSchema.primaryColor.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: ColorSchema.primaryColor.withValues(alpha: 0.12),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Comanda ${comanda.numeroComanda ?? (index + 1)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: ColorSchema.primaryColor,
                          ),
                        ),
                      ),
                      Text(
                        _formatDateTime(comanda.fecha),
                        style: const TextStyle(fontSize: 12, color: ColorSchema.primaryColor),
                      ),
                    ],
                  ),
                ),
                ...items.where((i) => !ComandaDetailStatus.isCancelledItem(i)).map((item) => _CommandaItemRow(
                      item: item,
                      onServir: (comanda.id != null && item.id != null)
                          ? () => ref
                                .read(restaurantProvider.notifier)
                                .updateCommandItemStatus(comanda.id!, item.id!, 'DESPACHADO')
                          : null,
                      onAnular: (comanda.id != null && item.id != null)
                          ? () => ref
                                .read(restaurantProvider.notifier)
                                .updateCommandItemStatus(comanda.id!, item.id!, 'CANCELADO')
                          : null,
                    )),
                if (items.any(ComandaDetailStatus.isCancelledItem))
                  _CancelledItemsBar(
                    items: items.where(ComandaDetailStatus.isCancelledItem).toList(),
                  ),
                _buildSubtotalRow(subtotal),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCuentasView(OrderRestaurant order) {
    final cuentas = order.cuentas ?? [];
    if (cuentas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Sin cuentas creadas', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    final itemsMap = _buildCuentasItemsMap(order);
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: cuentas.length,
      itemBuilder: (context, index) {
        final cuenta = cuentas[index];
        final items = itemsMap[cuenta.id] ?? cuenta.items ?? [];
        final subtotal = items.fold<double>(
          0.0,
          (s, i) => ComandaDetailStatus.isCancelledItem(i)
              ? s
              : s + ((i.precioVenta ?? 0.0) * (i.cantidad ?? 1.0)),
        );
        final isPagado = cuenta.pagado == true;
        final cardBg = isPagado
            ? const Color(0xFFF1FBF4)
            : const Color(0xFFFFF8F0);
        final accentColor = isPagado
            ? const Color(0xFF2E7D32)
            : const Color(0xFFE65100);
        final headerBg = accentColor.withValues(alpha: 0.13);
        final borderColor = accentColor;
        return GestureDetector(
          onTap: isPagado ? null : () => _showCuentaSheet(context, cuenta, index),
          child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: headerBg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPagado ? Icons.check_circle_rounded : Icons.receipt_long_rounded,
                        color: accentColor,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          cuenta.cliente?.razonSocial != null
                              ? 'Cuenta ${index + 1} · ${cuenta.cliente!.razonSocial}'
                              : 'Cuenta ${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: accentColor,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isPagado ? 'Pagado' : 'Pendiente',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Text(
                      'Sin productos asignados',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                  )
                else ...[
                  ...items.where((i) => !ComandaDetailStatus.isCancelledItem(i)).map(
                        (item) => _CommandaItemRow(item: item, showStatus: false),
                      ),
                  if (items.any(ComandaDetailStatus.isCancelledItem))
                    _CancelledItemsBar(
                      items: items.where(ComandaDetailStatus.isCancelledItem).toList(),
                      showStatus: false,
                    ),
                ],
                _buildSubtotalRow(subtotal),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  Future<void> _goPagar(Check check) async {
    if (check.id == null) return;
    // Capturar navigator y notifier ANTES del pop: una vez desmontado el
    // widget, tanto context como ref dejan de ser válidos.
    final nav = Navigator.of(context);
    final notifier = ref.read(productSaleProvider.notifier);
    nav.pop();
    try {
      final fullCheck = await RestaurantRepositoryImpl().getCheckById(check.id!);
      await notifier.initFromCheck(fullCheck);
      nav.push(
        MaterialPageRoute(builder: (_) => const ProductsSaleScreen()),
      );
    } catch (e) {
      errorNotification('Error al cargar la cuenta: $e');
    }
  }

  void _showCuentaSheet(BuildContext context, Check cuenta, int index) {
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        cuenta.cliente?.razonSocial != null
                            ? 'Cuenta ${index + 1} · ${cuenta.cliente!.razonSocial}'
                            : 'Cuenta ${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Divider(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: 4),
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  _goPagar(cuenta);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: ColorSchema.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.payment_rounded,
                          color: ColorSchema.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Ir a pagar cuenta',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: ColorSchema.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider so the dialog rebuilds when the order data is reloaded
    // (e.g. after servir/anular updates an item status).
    final updatedOrder = ref.watch(restaurantProvider).orders.firstWhere(
      (o) => o.id == widget.order.id,
      orElse: () => widget.order,
    );
    final order = updatedOrder;
    final isPendiente = order.estado == 'PENDIENTE';
    final hasItemPreparado = isPendiente &&
        (order.comandas ?? []).any(
          (c) => (c.items ?? []).any(
            (item) =>
                item.estadoComandaDetalle?.toUpperCase() == 'PREPARADO' &&
                item.eliminado != true,
          ),
        );
    final comandas = order.comandas ?? [];

    double grandTotal = 0.0;
    for (final c in comandas) {
      for (final item in (c.items ?? [])) {
        if (ComandaDetailStatus.isCancelledItem(item)) continue;
        grandTotal += (item.precioVenta ?? 0.0) * (item.cantidad ?? 1.0);
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 8, 0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Detalle de orden',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '#${formatOrderNumber(order.numeroOrden)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    if (order.mesa != null)
                      Text(
                        'Mesa ${order.mesa?.numero ?? order.mesa?.id ?? '-'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color.fromARGB(255, 65, 65, 65),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Tab bar
          ColoredBox(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: ColorSchema.primaryColor,
              unselectedLabelColor: Colors.grey.shade500,
              indicatorColor: ColorSchema.primaryColor,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'Orden'),
                Tab(text: 'Comandas'),
                Tab(text: 'Cuentas'),
              ],
            ),
          ),
          const Divider(height: 1),
          // Tab content
          ColoredBox(
            color: const Color.fromARGB(255, 223, 228, 247),
            child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrdenView(order, hasItemPreparado, isPendiente),
                _buildComandasView(comandas),
                _buildCuentasView(order),
              ],
            ),
          ),
          ),
          // Grand total footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: ColorSchema.primaryColor,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (order.montoDelivery != null && order.montoDelivery! > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Delivery',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'S/. ${order.montoDelivery!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'S/. ${grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Comanda item row with status colors, payment badge, action button ────────

class _CommandaItemRow extends StatefulWidget {
  final CommandDetail item;
  final VoidCallback? onServir;
  final VoidCallback? onAnular;
  final bool showStatus;

  const _CommandaItemRow({
    required this.item,
    this.onServir,
    this.onAnular,
    this.showStatus = true,
  });

  @override
  State<_CommandaItemRow> createState() => _CommandaItemRowState();
}

class _CommandaItemRowState extends State<_CommandaItemRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: 4).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isCancelled = ComandaDetailStatus.isCancelledItem(item);
    final status = item.estadoComandaDetalle?.toUpperCase() ?? ComandaDetailStatus.pendiente;
    final isPagado = item.cuenta?.pagado == true;
    final hasActions =
        !isCancelled && !isPagado && (widget.onServir != null || widget.onAnular != null);
    final grupoOpciones =
        (item.grupoProductoOpciones ?? []).where((o) => o.eliminado != true).toList();
    final hasGroups = grupoOpciones.isNotEmpty;

    final textDecor = isCancelled ? TextDecoration.lineThrough : TextDecoration.none;
    final mainColor = isCancelled ? Colors.red.shade400 : Colors.black87;
    final bgColor = Colors.white;
    final borderAccent = isCancelled
        ? Colors.red.shade300
        : isPagado
            ? const Color(0xFF2E7D32)
            : statusBorderColor(status);
    final total = (item.precioVenta ?? 0) * (item.cantidad ?? 1);

    return GestureDetector(
      onTap: hasActions
          ? () => ItemActionBottomSheet.show(
                context,
                item: item,
                status: status,
                onServir: widget.onServir,
                onAnular: widget.onAnular,
              )
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            left: BorderSide(color: borderAccent, width: 3),
            bottom: BorderSide(color: Colors.grey.shade300, width: 1.0),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // ── Row 1: pagado + status (left) · arrow (right) ─────────────
          Row(
            children: [
              if (!isCancelled) ...[
                if (widget.showStatus && !isPagado && status != ComandaDetailStatus.pendiente) ...[
                  ComandaStatusBadge(status: status, fontSize: 8),
                  const SizedBox(width: 4),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPagado ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isPagado ? 'Pagado' : 'Por pagar',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isPagado ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (hasActions)
                AnimatedBuilder(
                  animation: _bounceAnim,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(_bounceAnim.value, 0),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: borderAccent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          // ── Row 2: qty + name + price ──────────────────────────────────
          Row(
            children: [
              Text(
                '${item.cantidad?.toInt() ?? 1}x',
                style: TextStyle(
                  color: isCancelled ? Colors.red.shade400 : Colors.grey.shade600,
                  fontSize: isCancelled ? 11 : 13,
                  fontWeight: FontWeight.w600,
                  decoration: textDecor,
                  decorationColor: Colors.red.shade400,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.producto?.nombre ?? '-',
                  style: TextStyle(
                    fontSize: isCancelled ? 11 : 13,
                    fontWeight: FontWeight.w500,
                    color: mainColor,
                    decoration: textDecor,
                    decorationColor: Colors.red.shade400,
                  ),
                ),
              ),
              Text(
                'S/. ${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: isCancelled ? 11 : 13,
                  fontWeight: FontWeight.w600,
                  color: mainColor,
                  decoration: textDecor,
                  decorationColor: Colors.red.shade400,
                ),
              ),
            ],
          ),
          // ── Group options (expanded) ───────────────────────────────────
          if (hasGroups) ...[
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: grupoOpciones.map((o) {
                  final subColor = isCancelled ? Colors.red.shade300 : Colors.grey.shade600;
                  final optPrice = (o.precio ?? 0) * (o.cantidad ?? 1);
                  final name = o.nombreOpcion ?? o.nombreGrupo ?? '-';
                  return Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Icon(Icons.subdirectory_arrow_right_rounded,
                            size: 11, color: Colors.grey.shade400),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${(o.cantidad ?? 1).toInt()}x $name',
                            style: TextStyle(
                              fontSize: 11,
                              color: subColor,
                              decoration: textDecor,
                              decorationColor: Colors.red.shade300,
                            ),
                          ),
                        ),
                        if (optPrice > 0)
                          Text(
                            'S/. ${optPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: subColor,
                              decoration: textDecor,
                              decorationColor: Colors.red.shade300,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }
}

// ─── Cancelled items collapsible bar ─────────────────────────────────────────

class _CancelledItemsBar extends StatefulWidget {
  final List<CommandDetail> items;
  final bool showStatus;

  const _CancelledItemsBar({required this.items, this.showStatus = true});

  @override
  State<_CancelledItemsBar> createState() => _CancelledItemsBarState();
}

class _CancelledItemsBarState extends State<_CancelledItemsBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final count = widget.items.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.red.shade300, width: 3),
                bottom: BorderSide(color: Colors.grey.shade300, width: 1.0),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: Row(
              children: [
                Text(
                  '$count ${count == 1 ? 'item anulado' : 'items anulados'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red.shade300,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _expanded ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 13,
                  color: Colors.red.shade300,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          ...widget.items.map(
            (item) => _CommandaItemRow(item: item, showStatus: widget.showStatus),
          ),
      ],
    );
  }
}

// ─── Order info row ───────────────────────────────────────────────────────────

class _OrderInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBadge;

  const _OrderInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = valueColor ?? Colors.black87;
    Widget valueWidget = Text(
      value,
      textAlign: TextAlign.end,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
    );
    if (valueBadge && valueColor != null) {
      valueWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: valueColor!.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: valueColor!.withValues(alpha: 0.25)),
        ),
        child: Text(
          value,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: valueColor),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 15, color: ColorSchema.primaryColor.withValues(alpha: 0.7)),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: ColorSchema.primaryColor.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: valueWidget),
          ),
        ],
      ),
    );
  }
}

/// Row with two values stacked vertically on the right side.
class _StackedInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value1;
  final String? value2;

  const _StackedInfoRow({
    required this.icon,
    required this.label,
    required this.value1,
    this.value2,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 15, color: ColorSchema.primaryColor.withValues(alpha: 0.7)),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: ColorSchema.primaryColor.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value1,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                if (value2 != null)
                  Text(
                    value2!,
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _estadoPedidoOnlineColor(String estado) {
  switch (estado) {
    case 'ACEPTADO':             return const Color(0xFF2E7D32);
    case 'CANCELADO':
    case 'RECHAZADO':            return const Color(0xFFC62828);
    case 'PENDIENTE_ACEPTACION': return const Color(0xFFE65100);
    default:                     return Colors.black87;
  }
}

Color _estadoPedidoOnlineBgColor(String estado) {
  switch (estado) {
    case 'ACEPTADO':             return const Color.fromARGB(255, 230, 255, 232);
    case 'CANCELADO':
    case 'RECHAZADO':            return const Color(0xFFFFD6D6);
    case 'PENDIENTE_ACEPTACION': return const Color(0xFFFFE5CC);
    default:                     return const Color(0xFFF0F0F0);
  }
}

Color _estadoDeliveryColor(String estado) {
  switch (estado) {
    case 'ENTREGADO': return const Color(0xFF2E7D32);
    case 'ENVIADO':   return const Color(0xFF1565C0);
    case 'CANCELADO': return const Color(0xFFC62828);
    case 'PENDIENTE': return const Color(0xFFE65100);
    default:          return Colors.black87;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Card with a floating label overlapping the top-left border.
/// Optionally accepts a [trailing] widget that floats on the top-right border.
class _LabeledInfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? trailing;

  const _LabeledInfoCard({required this.title, required this.children, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 10),
            padding: EdgeInsets.fromLTRB(14, trailing != null ? 26 : 16, 14, 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
          Positioned(
            top: 0,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ColorSchema.primaryColor,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          if (trailing != null)
            Positioned(
              top: 0,
              right: 12,
              child: trailing!,
            ),
        ],
      ),
    );
  }
}

/// Card with client info, shown only when at least one field has data.
class _ClienteInfoCard extends StatelessWidget {
  final Customer? cliente;

  const _ClienteInfoCard({required this.cliente});

  @override
  Widget build(BuildContext context) {
    final nombre = cliente?.razonSocial?.isNotEmpty == true ? cliente!.razonSocial! : null;
    final telefono = cliente?.telefono?.isNotEmpty == true ? cliente!.telefono! : null;
    if (nombre == null && telefono == null) return const SizedBox.shrink();
    return _LabeledInfoCard(
      title: 'Cliente',
      children: [
        if (nombre != null)
          _OrderInfoRow(icon: Icons.person_outline_rounded, label: 'Nombre', value: nombre),
        if (telefono != null)
          _OrderInfoRow(icon: Icons.phone_outlined, label: 'Teléfono', value: telefono),
      ],
    );
  }
}

/// Card with address info, shown only when at least one field has data.
class _DireccionInfoCard extends StatelessWidget {
  final String? direccionCompleta;
  final String? referencia;
  final double? montoDelivery;

  const _DireccionInfoCard({
    this.direccionCompleta,
    this.referencia,
    this.montoDelivery,
  });

  @override
  Widget build(BuildContext context) {
    final dir = direccionCompleta?.isNotEmpty == true ? direccionCompleta! : null;
    final ref = referencia?.isNotEmpty == true ? referencia! : null;
    final monto = (montoDelivery != null && montoDelivery! > 0) ? montoDelivery : null;
    if (dir == null && ref == null && monto == null) return const SizedBox.shrink();
    return _LabeledInfoCard(
      title: 'Dirección',
      children: [
        if (dir != null)
          _OrderInfoRow(icon: Icons.location_on_outlined, label: 'Dirección', value: dir),
        if (ref != null)
          _OrderInfoRow(icon: Icons.signpost_outlined, label: 'Referencia', value: ref),
        if (monto != null)
          _OrderInfoRow(
            icon: Icons.delivery_dining_outlined,
            label: 'Costo delivery',
            value: 'S/. ${monto.toStringAsFixed(2)}',
          ),
      ],
    );
  }
}

/// Card with online order info, shown only when at least one field has data.
class _OnlineInfoCard extends StatelessWidget {
  final String? estadoOnline;
  final String? formaPago;
  final String? nombreFormaPago;
  final Delivery? envio;

  const _OnlineInfoCard({
    this.estadoOnline,
    this.formaPago,
    this.nombreFormaPago,
    this.envio,
  });

  @override
  Widget build(BuildContext context) {
    final online = estadoOnline?.isNotEmpty == true ? estadoOnline! : null;
    final fpCodigo = formaPago?.isNotEmpty == true ? formaPago! : null;
    final fpNombre = nombreFormaPago?.isNotEmpty == true ? nombreFormaPago! : null;
    final estadoEnvio = envio?.estado?.isNotEmpty == true ? envio!.estado! : null;
    final repartidor = envio?.repartidor?.nombreCompleto?.isNotEmpty == true
        ? envio!.repartidor!.nombreCompleto!
        : null;
    if (online == null && fpCodigo == null && fpNombre == null &&
        estadoEnvio == null && repartidor == null) {
      return const SizedBox.shrink();
    }
    final onlineColor = online != null ? _estadoPedidoOnlineColor(online) : null;
    final onlineBgColor = online != null ? _estadoPedidoOnlineBgColor(online) : null;
    return _LabeledInfoCard(
      title: 'Información Online',
      trailing: online != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: onlineBgColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: onlineColor!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_outlined, size: 11, color: onlineColor),
                  const SizedBox(width: 4),
                  Text(
                    online,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: onlineColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            )
          : null,
      children: [
        if (estadoEnvio != null)
          _OrderInfoRow(
            icon: Icons.delivery_dining_outlined,
            label: 'Estado envío',
            value: estadoEnvio,
            valueColor: _estadoDeliveryColor(estadoEnvio),
            valueBadge: true,
          ),
        if (repartidor != null)
          _OrderInfoRow(icon: Icons.person_pin_circle_outlined, label: 'Repartidor', value: repartidor),
        if (fpCodigo != null || fpNombre != null)
          _StackedInfoRow(
            icon: Icons.payment_outlined,
            label: 'Forma de pago',
            value1: fpCodigo ?? fpNombre!,
            value2: fpCodigo != null ? fpNombre : null,
          ),
      ],
    );
  }
}

