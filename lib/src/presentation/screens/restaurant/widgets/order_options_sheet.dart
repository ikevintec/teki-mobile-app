import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/data/models/teki_model/check.dart';
import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/commandDetail.dart';
import 'package:teki_app/src/data/models/teki_model/orderRestaurant.dart';
import 'package:teki_app/src/presentation/screens/restaurant/widgets/comanda_detail_item_tile.dart';
import 'package:teki_app/src/data/repositories/restaurant_repository_impl.dart';
import 'package:teki_app/src/presentation/screens/sale/products/products_sale_screen.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/restaurant/restaurant_provider.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/formats.dart';
import 'package:teki_app/src/utils/notifications.dart';

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
    showDialog(
      context: context,
      builder: (_) => _OrderDetailDialog(order: order),
    );
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
      builder: (_) => const _AnularOrdenDialog(),
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

class _AnularOrdenDialog extends StatefulWidget {
  const _AnularOrdenDialog();

  @override
  State<_AnularOrdenDialog> createState() => _AnularOrdenDialogState();
}

class _AnularOrdenDialogState extends State<_AnularOrdenDialog> {
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

  Widget _buildItemRow(CommandDetail item) {
    final isCancelled = ComandaDetailStatus.isCancelledItem(item);
    final textDecor = isCancelled ? TextDecoration.lineThrough : TextDecoration.none;
    final mainColor = isCancelled ? Colors.red.shade400 : Colors.black87;
    final grupoOpciones =
        (item.grupoProductoOpciones ?? []).where((o) => o.eliminado != true).toList();

    return Container(
      color: isCancelled ? Colors.red.shade50 : null,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Main row ───────────────────────────────────────────────────
          Row(
            children: [
              Text(
                '${item.cantidad ?? 1}x',
                style: TextStyle(
                  color: isCancelled ? Colors.red.shade400 : Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  decoration: textDecor,
                  decorationColor: Colors.red.shade400,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.producto?.nombre ?? '-',
                  style: TextStyle(
                    fontSize: 13,
                    color: mainColor,
                    decoration: textDecor,
                    decorationColor: Colors.red.shade400,
                  ),
                ),
              ),
              Text(
                'S/. ${((item.precioVenta ?? 0) * (item.cantidad ?? 1)).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 13,
                  color: mainColor,
                  decoration: textDecor,
                  decorationColor: Colors.red.shade400,
                ),
              ),
            ],
          ),
          // ── Group options sub-items ─────────────────────────────────────
          if (grupoOpciones.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 22, top: 2),
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
      ),
    );
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
        final items = comanda.items ?? [];
        final subtotal = items.fold<double>(
          0.0,
          (s, i) => ComandaDetailStatus.isCancelledItem(i)
              ? s
              : s + ((i.precioVenta ?? 0.0) * (i.cantidad ?? 1.0)),
        );
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ColorSchema.primaryColor.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
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
                ...items.map((item) => _buildItemRow(item)),
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
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
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
                else
                  ...items.map((item) => _buildItemRow(item)),
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

  Widget _buildAccionesView(List<Command> comandas) {
    // Flatten all items from all comandas into a single list, preserving
    // a reference to their parent comanda id and number.
    final entries = <({CommandDetail item, int? commandId, int? numeroComanda})>[];
    for (final comanda in comandas) {
      for (final item in (comanda.items ?? [])) {
        entries.add((item: item, commandId: comanda.id, numeroComanda: comanda.numeroComanda));
      }
    }

    // Sort: PREPARADO → PENDIENTE → DESPACHADO → CANCELADO
    const statusOrder = {
      'PREPARADO': 0,
      'PENDIENTE': 1,
      'DESPACHADO': 2,
      'CANCELADO': 3,
    };
    entries.sort((a, b) {
      final aStatus = (a.item.estadoComandaDetalle?.toUpperCase() ?? 'PENDIENTE');
      final bStatus = (b.item.estadoComandaDetalle?.toUpperCase() ?? 'PENDIENTE');
      return (statusOrder[aStatus] ?? 1).compareTo(statusOrder[bStatus] ?? 1);
    });

    if (entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Sin productos', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final e = entries[index];
        final commandId = e.commandId;
        final itemId = e.item.id;
        return ComandaDetailItemTile(
          item: e.item,
          numeroComanda: e.numeroComanda,
          showComandaBadge: true,
          interactive: true,
          onServir: (commandId != null && itemId != null)
              ? () => ref
                    .read(restaurantProvider.notifier)
                    .updateCommandItemStatus(commandId, itemId, 'DESPACHADO')
              : null,
          onAnular: (commandId != null && itemId != null)
              ? () => ref
                    .read(restaurantProvider.notifier)
                    .updateCommandItemStatus(commandId, itemId, 'CANCELADO')
              : null,
        );
      },
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Detalle de orden',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Order info strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: Colors.grey.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.start,
                  children: [
                    _InfoChip(
                      icon: Icons.tag,
                      value: formatOrderNumber(order.numeroOrden).toString(),
                      color: ColorSchema.primaryColor,
                    ),
                    _InfoChip(
                      icon: Icons.table_restaurant_rounded,
                      value: 'Mesa ${order.mesa?.numero ?? order.mesa?.id ?? '-'}',
                      color: ColorSchema.primaryColor,
                    ),
                    _InfoChip(
                      icon: Icons.local_dining_rounded,
                      value: order.tipo ?? '-',
                      color: ColorSchema.primaryColor,
                    ),
                    if (order.numeroComensales != null)
                      _InfoChip(
                        icon: Icons.people_alt_rounded,
                        value: '${order.numeroComensales}',
                        color: ColorSchema.primaryColor,
                      ),
                  ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasItemPreparado
                            ? const Color(0xFFE65100).withValues(alpha: 0.12)
                            : isPendiente
                                ? const Color(0xFF1565C0).withValues(alpha: 0.12)
                                : const Color(0xFF2E7D32).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        hasItemPreparado ? 'PREPARADO' : (order.estado ?? '-'),
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
                    const SizedBox(width: 10),
                    const Icon(Icons.access_time_rounded, size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _formatElapsed(_elapsed),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'en mesa',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
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
                Tab(text: 'Comandas'),
                Tab(text: 'Cuentas'),
                Tab(text: 'Acciones'),
              ],
            ),
          ),
          const Divider(height: 1),
          // Tab content
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildComandasView(comandas),
                _buildCuentasView(order),
                _buildAccionesView(comandas),
              ],
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
            child: Row(
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
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _InfoChip({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
