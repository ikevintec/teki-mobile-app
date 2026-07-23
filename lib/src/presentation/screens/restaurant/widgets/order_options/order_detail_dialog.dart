import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/check.dart';
import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail.dart';
import 'package:teki_app/src/data/models/teki_model/order_restaurant.dart';
import 'package:teki_app/src/data/repositories/restaurant_repository_impl.dart';
import 'package:teki_app/src/presentation/screens/restaurant/widgets/comanda_detail_item_tile.dart';
import 'package:teki_app/src/presentation/screens/restaurant/widgets/order_options/cancelled_items_bar.dart';
import 'package:teki_app/src/presentation/screens/restaurant/widgets/order_options/comanda_item_row.dart';
import 'package:teki_app/src/presentation/screens/restaurant/widgets/order_options/order_info_cards.dart';
import 'package:teki_app/src/presentation/screens/sale/products/products_sale_screen.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/restaurant/restaurant_provider.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/shared/services/command_print_service.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';
import 'package:teki_app/src/utils/notifications.dart';

void showOrderDetailDialog(BuildContext context, OrderRestaurant order) {
  showDialog(
    context: context,
    builder: (ctx) => MediaQuery(
      data: MediaQuery.of(ctx).copyWith(viewInsets: EdgeInsets.zero),
      child: OrderDetailDialog(order: order),
    ),
  );
}

class OrderDetailDialog extends ConsumerStatefulWidget {
  final OrderRestaurant order;

  const OrderDetailDialog({super.key, required this.order});

  @override
  ConsumerState<OrderDetailDialog> createState() => OrderDetailDialogState();
}

class OrderDetailDialogState extends ConsumerState<OrderDetailDialog>
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
          LabeledInfoCard(
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
              OrderInfoRow(
                icon: Icons.access_time_rounded,
                label: 'Tiempo en mesa',
                value: _formatElapsed(_elapsed),
              ),
              if ((order.mesa?.numero ?? order.mesa?.id) != null)
                OrderInfoRow(
                  icon: Icons.table_restaurant_rounded,
                  label: 'Mesa',
                  value: 'Mesa ${order.mesa?.numero ?? order.mesa?.id}',
                ),
              if (order.tipo?.isNotEmpty == true)
                OrderInfoRow(
                  icon: Icons.local_dining_rounded,
                  label: 'Tipo',
                  value: normalizeEnumLabel(order.tipo),
                ),
              if (order.numeroComensales != null)
                OrderInfoRow(
                  icon: Icons.people_alt_rounded,
                  label: 'Comensales',
                  value: '${order.numeroComensales}',
                ),
              if ((order.usuario?.nombreCompleto ?? order.usuario?.name)?.isNotEmpty == true)
                OrderInfoRow(
                  icon: Icons.person_rounded,
                  label: 'Atendido por',
                  value: order.usuario!.nombreCompleto ?? order.usuario!.name!,
                ),
              if (order.fecha != null)
                OrderInfoRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Apertura',
                  value: _formatDateTime(order.fecha),
                ),
            ],
          ),
          // Cliente (solo DELIVERY)
          if (isDelivery) ClienteInfoCard(cliente: order.cliente),
          // Dirección (si hay data)
          DireccionInfoCard(
            direccionCompleta: order.direccionCompleta,
            referencia: order.referencia,
            montoDelivery: order.montoDelivery,
          ),
          // Información Online (solo PEDIDO_ONLINE)
          if (isPedidoOnline)
            OnlineInfoCard(
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
                ...items.where((i) => !ComandaDetailStatus.isCancelledItem(i)).map((item) => CommandaItemRow(
                      item: item,
                      onServir: (comanda.id != null && item.id != null)
                          ? (cantidad) => ref
                                .read(restaurantProvider.notifier)
                                .updateCommandItemStatus(comanda.id!, item.id!, 'DESPACHADO', cantidad: cantidad)
                          : null,
                      onAnular: (comanda.id != null &&
                              item.id != null &&
                              ref.read(sesionProvider).hasPermission(
                                  'RESTAURANTE_PEDIDOS_CANCELAR_PLATILLO'))
                          ? (motivo, cantidad) {
                              final commandId = comanda.id!;
                              ref
                                  .read(restaurantProvider.notifier)
                                  .updateCommandItemStatus(commandId, item.id!, 'CANCELADO', motivoAnulacion: motivo, cantidad: cantidad)
                                  .then((_) {
                                    final sesion = ref.read(sesionProvider);
                                    final office = sesion.office;
                                    if (office?.id != null) {
                                      CommandPrintService().processCommand(
                                        commandId: commandId,
                                        puntoVenta: office!,
                                        escPos: sesion.config?.imprimeTicketsEscPos ?? false,
                                        clientPrinter: sesion.config?.clienteImpresion,
                                        idCompany: sesion.company?.id,
                                        anulacion: true,
                                        itemAfectado: [item.id!],
                                      );
                                    }
                                  });
                            }
                          : null,
                    )),
                if (items.any(ComandaDetailStatus.isCancelledItem))
                  CancelledItemsBar(
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
                        (item) => CommandaItemRow(item: item, showStatus: false),
                      ),
                  if (items.any(ComandaDetailStatus.isCancelledItem))
                    CancelledItemsBar(
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
