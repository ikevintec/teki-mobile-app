import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/check.dart';
import 'package:teki_app/src/data/models/teki_model/commandDetail.dart';
import 'package:teki_app/src/data/models/teki_model/commandDetailGroupOption.dart';
import 'package:teki_app/src/data/models/teki_model/commandDetailPreparationOption.dart';
import 'package:teki_app/src/data/models/teki_model/orderRestaurant.dart';
import 'package:teki_app/src/data/repositories/restaurant_repository_impl.dart';
import 'package:teki_app/src/presentation/screens/sale/products/products_sale_screen.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/notifications.dart';

/// Screen shown automatically when the order_ready notification filter returns
/// exactly 1 order with 1 cuenta and all its active items are 'PREPARADO'.
/// Pressing "Ir a pagar" pops this screen back to the orders list and then
/// pushes [ProductsSaleScreen], so back-navigation lands on the orders page.
class OrderReadyToPayScreen extends ConsumerStatefulWidget {
  final OrderRestaurant order;
  final Check cuenta;

  const OrderReadyToPayScreen({
    super.key,
    required this.order,
    required this.cuenta,
  });

  /// Indica si esta pantalla está actualmente en la pila de navegación.
  /// Usado por [NotificationService] para hacer pop antes de apilar una nueva.
  static bool isVisible = false;

  @override
  ConsumerState<OrderReadyToPayScreen> createState() =>
      _OrderReadyToPayScreenState();
}

class _OrderReadyToPayScreenState extends ConsumerState<OrderReadyToPayScreen> {
  bool _isPaying = false;

  @override
  void initState() {
    super.initState();
    OrderReadyToPayScreen.isVisible = true;
  }

  @override
  void dispose() {
    OrderReadyToPayScreen.isVisible = false;
    super.dispose();
  }

  List<CommandDetail> get _activeItems =>
      (widget.order.comandas![0].items ?? [])
          .where((i) => i.eliminado != true)
          .toList();

  double get _subtotal => _activeItems.fold(
        0.0,
        (s, i) => s + (i.precioVenta ?? 0.0) * (i.cantidad ?? 1.0),
      );

  Future<void> _goPagar() async {
    if (_isPaying || widget.cuenta.id == null) return;
    setState(() => _isPaying = true);
    // Capture navigator and notifier BEFORE pop (context invalid after pop).
    final nav = Navigator.of(context);
    final notifier = ref.read(productSaleProvider.notifier);
    nav.pop(); // close this screen → ordersRestaurant is now on top
    try {
      final fullCheck =
          await RestaurantRepositoryImpl().getCheckById(widget.cuenta.id!);
      await notifier.initFromCheck(fullCheck);
      nav.push(MaterialPageRoute(builder: (_) => const ProductsSaleScreen()));
    } catch (e) {
      errorNotification('Error al cargar la cuenta: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final items = _activeItems;
    final subtotal = _subtotal;
    final montoDelivery =
        (order.montoDelivery != null && order.montoDelivery! > 0)
            ? order.montoDelivery!
            : null;
    final total = subtotal + (montoDelivery ?? 0);

    final mesaLabel = order.mesa?.numero != null
        ? 'Mesa ${order.mesa!.numero}'
        : null;
    final clienteNombre = (order.nombreCliente?.isNotEmpty == true)
        ? order.nombreCliente
        : order.cliente?.razonSocial;
    final telefono = (order.cliente?.telefono?.isNotEmpty == true)
        ? order.cliente!.telefono
        : (order.telefonoReceptor?.isNotEmpty == true
            ? order.telefonoReceptor
            : null);
    final tipoLabel = order.tipo != null ? _tipoLabel(order.tipo) : null;
    final direccionEnvio = (order.direccionCompleta?.isNotEmpty == true)
        ? order.direccionCompleta
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: ColorSchema.primaryColor,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.payment_rounded, size: 20, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Lista para cobrar',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Ready banner ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFF66BB6A), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF66BB6A),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.restaurant_rounded,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pedido listo para cobrar',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Todos los platos han sido preparados',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2E7D32)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Order info ───────────────────────────────────────
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.receipt_long_rounded,
                        label: 'Orden #${order.numeroOrden ?? order.id ?? '-'}',
                        color: const Color(0xFF1565C0),
                        bgColor: const Color(0xFFE3F2FD),
                        borderColor: const Color(0xFF90CAF9),
                      ),
                      if (tipoLabel != null)
                        _InfoChip(
                          icon: Icons.category_rounded,
                          label: tipoLabel,
                          color: const Color(0xFF1565C0),
                          bgColor: const Color(0xFFE3F2FD),
                          borderColor: const Color(0xFF90CAF9),
                        ),
                      if (mesaLabel != null)
                        _InfoChip(
                          icon: Icons.table_restaurant_rounded,
                          label: mesaLabel,
                          color: const Color(0xFF7B1FA2),
                          bgColor: const Color(0xFFF3E5F5),
                          borderColor: const Color(0xFFCE93D8),
                        ),
                      if (clienteNombre != null)
                        _InfoChip(
                          icon: Icons.person_rounded,
                          label: clienteNombre,
                          color: const Color(0xFF37474F),
                          bgColor: const Color(0xFFECEFF1),
                          borderColor: const Color(0xFFB0BEC5),
                        ),
                      if (telefono != null)
                        _InfoChip(
                          icon: Icons.phone_rounded,
                          label: telefono,
                          color: const Color(0xFF2E7D32),
                          bgColor: const Color(0xFFE8F5E9),
                          borderColor: const Color(0xFF81C784),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Dirección de envío ───────────────────────────────
                  if (direccionEnvio != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFCC02)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 18, color: Color(0xFFF57F17)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Dirección de envío',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFF57F17),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  direccionEnvio,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF5D4037),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Cuenta card ──────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(14)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.receipt_long_rounded,
                                  size: 16, color: Color(0xFF2E7D32)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  clienteNombre != null
                                      ? 'Detalle · $clienteNombre'
                                      : 'Detalle del pedido',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF66BB6A)
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Pendiente',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Items
                        if (items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Sin productos',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade500),
                            ),
                          )
                        else
                          ...items.map((item) => _ItemRow(item: item)),

                        // Totales
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                          decoration: const BoxDecoration(
                            border: Border(
                                top: BorderSide(color: Color(0xFFEEEEEE))),
                          ),
                          child: Column(
                            children: [
                              if (montoDelivery != null) ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Subtotal',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600),
                                    ),
                                    Text(
                                      'S/. ${subtotal.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.delivery_dining_rounded,
                                            size: 14,
                                            color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Delivery',
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'S/. ${montoDelivery.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                                const SizedBox(height: 8),
                              ],
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    'S/. ${total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF1565C0),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Fixed pay button ─────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isPaying ? null : _goPagar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        const Color(0xFF1565C0).withValues(alpha: 0.7),
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: _isPaying ? 0 : 3,
                    shadowColor:
                        const Color(0xFF1565C0).withValues(alpha: 0.4),
                  ),
                  child: _isPaying
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Cargando...',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payment_rounded, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Ir a pagar cuenta',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info chip ────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final Color borderColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Item row (con grupos y preparaciones) ────────────────────────────────────

class _ItemRow extends StatelessWidget {
  final CommandDetail item;
  const _ItemRow({required this.item});

  List<Widget> _buildGrupos(List<CommandDetailGroupOption> grupos) {
    return grupos.map((o) {
      final qty = (o.cantidad ?? 1).toInt();
      final name = o.nombreOpcion ?? o.nombreGrupo ?? '-';
      final price = (o.precio ?? 0) * (o.cantidad ?? 1);
      return Padding(
        padding: const EdgeInsets.only(left: 12, top: 3),
        child: Row(
          children: [
            Icon(Icons.subdirectory_arrow_right_rounded,
                size: 13, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${qty}x $name',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
            if (price > 0)
              Text(
                'S/. ${price.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildPreparaciones(
      List<CommandDetailPreparationOption> preps) {
    final Map<String, List<CommandDetailPreparationOption>> grouped = {};
    for (final p in preps) {
      final key = p.nombrePreparacion ?? 'Preparación';
      grouped.putIfAbsent(key, () => []).add(p);
    }
    return grouped.entries.map((e) {
      return Padding(
        padding: const EdgeInsets.only(left: 12, top: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.tune_rounded, size: 13, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  children: [
                    TextSpan(
                      text: '${e.key}: ',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(
                      text: e.value
                          .map((o) => o.nombreOpcion ?? '-')
                          .join(', '),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final qty = (item.cantidad ?? 1).toInt();
    final price = (item.precioVenta ?? 0) * (item.cantidad ?? 1);
    final name = item.producto?.nombre ?? '-';
    final imagenUrl = item.producto?.imagenUrl;
    final grupos = (item.grupoProductoOpciones ?? [])
        .where((o) => o.eliminado != true)
        .toList();
    final preps = (item.preparacionProductoOpciones ?? [])
        .where((o) => o.eliminado != true)
        .toList();

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF5F5F5))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Producto principal (con thumbnail a la izquierda si hay imagen)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Thumbnail
                    if (imagenUrl != null && imagenUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: Image.network(
                              imagenUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (_, child, progress) =>
                                  progress == null
                                      ? child
                                      : Container(
                                          color: const Color(0xFFF5F5F5),
                                          child: const Center(
                                            child: SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 1.5,
                                                color: ColorSchema.primaryColor,
                                              ),
                                            ),
                                          ),
                                        ),
                              errorBuilder: (_, _, _) => Container(
                                color: const Color(0xFFF5F5F5),
                                child: Icon(Icons.broken_image_rounded,
                                    size: 24, color: Colors.grey.shade400),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Qty badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9A825).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${qty}x',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF9A825),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      'S/. ${price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                // Grupos de opciones
                if (grupos.isNotEmpty) ..._buildGrupos(grupos),
                // Preparaciones
                if (preps.isNotEmpty) ..._buildPreparaciones(preps),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
