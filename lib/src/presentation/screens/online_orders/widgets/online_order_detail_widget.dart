import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/online_order.dart';
import 'package:teki_app/src/presentation/screens/online_orders/widgets/order_action_button.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';
import 'package:teki_app/src/utils/price_formatter.dart';

class OnlineOrderDetailWidget extends StatelessWidget {
  final OnlineOrder order;

  const OnlineOrderDetailWidget({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 42,
            height: 4,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        _buildHeader(context),
        const SizedBox(height: 14),
        _section(
          icon: Icons.person_outline_rounded,
          title: 'Cliente',
          children: [
            _row('Nombre', order.nombreCliente ?? 'Sin nombre'),
            _row('Teléfono', order.telefonoCliente ?? '-'),
            if (order.emailCliente?.isNotEmpty == true)
              _row('Correo', order.emailCliente!),
            if (order.numeroDocumentoCliente?.isNotEmpty == true)
              _row('Documento', order.numeroDocumentoCliente!),
          ],
        ),
        const SizedBox(height: 10),
        _section(
          icon: Icons.location_on_outlined,
          title: 'Entrega',
          children: [
            _row('Modalidad', _deliveryLabel(order.tipoEntrega)),
            _row('Dirección', order.direccionEntrega ?? '-'),
            if (order.referenciaEntrega?.isNotEmpty == true)
              _row('Referencia', order.referenciaEntrega!),
          ],
        ),
        const SizedBox(height: 10),
        _section(
          icon: Icons.payments_outlined,
          title: 'Pago y comprobante',
          children: [
            _row('Método', _paymentLabel(order.metodoPago)),
            _row('Comprobante', _receiptLabel(order.tipoComprobante)),
            if (order.metodoPago == 'EFECTIVO' && order.montoEfectivo != null)
              _row('Cancela con', _money(order.montoEfectivo)),
            if ((order.montoDelivery ?? 0) > 0)
              _row('Delivery', _money(order.montoDelivery)),
            _row('Total', _money(order.total), emphasized: true),
          ],
        ),
        const SizedBox(height: 10),
        _section(
          icon: Icons.badge_outlined,
          title: 'Atención',
          children: [
            _row('Responsable', order.responsable?.displayName ?? '-'),
            _row('Fecha de atención', _attentionDate(order.tiempoAtencion)),
          ],
        ),
        if (order.imagenYape?.isNotEmpty == true) ...[
          const SizedBox(height: 10),
          _section(
            icon: Icons.image_outlined,
            title: 'Comprobante de Yape',
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  order.imagenYape!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No se pudo cargar la imagen.'),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (order.observacion?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFF92400E),
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    order.observacion!,
                    style: const TextStyle(
                      color: Color(0xFF78350F),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Productos (${order.items.length})',
          style: GoogleFonts.raleway(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        if (order.items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('El pedido no contiene productos.')),
          )
        else
          ...order.items.map(_itemCard),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final date = order.createdOn == null
        ? '-'
        : DateFormat('dd/MM/yyyy hh:mm a', 'es_PE').format(order.createdOn!);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ColorSchema.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            order.tipo == 'MENU'
                ? Icons.restaurant_menu_rounded
                : Icons.storefront_outlined,
            color: ColorSchema.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pedido #${formatOrderNumber(order.numeroPedido ?? order.id)}',
                style: GoogleFonts.raleway(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${order.tipo == 'MENU' ? 'Menú' : 'Catálogo'} · $date',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        _statusChip(order.estado),
      ],
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE6EAF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F263238),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: ColorSchema.primaryColor, size: 19),
              const SizedBox(width: 7),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool emphasized = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: emphasized ? 15 : 12.5,
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
                color: emphasized
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(OnlineOrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFE6EAF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A263238),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ColorSchema.primaryColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '${PriceFormatter.formatPrice(item.cantidad)}x',
                  style: const TextStyle(
                    color: ColorSchema.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nombreProducto ?? 'Producto',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (item.nombreVariante?.isNotEmpty == true)
                      Text(
                        item.nombreVariante!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                _money(item.precioTotal, currency: item.moneda),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (item.opciones.isNotEmpty) ...[
            const SizedBox(height: 7),
            ...item.opciones.map(
              (option) => Padding(
                padding: const EdgeInsets.only(left: 42, top: 2),
                child: Text(
                  '• ${option.nombreGrupo?.isNotEmpty == true ? '${option.nombreGrupo}: ' : ''}'
                  '${option.nombreOpcion ?? 'Opción'}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ],
          if (item.nota?.trim().isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(left: 42, top: 5),
              child: Text(
                'Nota: ${item.nota}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusChip(String? status) {
    final color = switch (status) {
      'PENDIENTE' => const Color(0xFFD97706),
      'ACEPTADO' => const Color(0xFF2563EB),
      'ANULADO' => const Color(0xFFDC2626),
      _ => const Color(0xFF16A34A),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        normalizeEnumLabel(status),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  String _money(double? amount, {String? currency}) =>
      '${formatExchange(moneda: currency ?? order.moneda ?? 'PEN')}'
      '${(amount ?? 0).toStringAsFixed(2)}';

  String _attentionDate(DateTime? value) => value == null
      ? '-'
      : DateFormat('dd/MM/yyyy hh:mm a', 'es_PE').format(value);

  String _deliveryLabel(String? value) => value == 'DELIVERY'
      ? 'Delivery'
      : value == 'RECOJO'
      ? 'Recojo'
      : '-';

  String _paymentLabel(String? value) => switch (value) {
    'EFECTIVO' => 'Efectivo',
    'YAPE' => 'Yape',
    'POS' => 'POS contraentrega',
    _ => normalizeEnumLabel(value),
  };

  String _receiptLabel(String? value) => switch (value) {
    'BOLETA_SIMPLE' => 'Boleta simple',
    'BOLETA_DNI' => 'Boleta con DNI',
    'FACTURA' => 'Factura',
    _ => normalizeEnumLabel(value),
  };
}

/// Barra de acciones fija (Aceptar / Anular) que se ancla al pie del detalle,
/// para no depender del scroll. Se oculta si el pedido no admite acciones.
class OnlineOrderDetailActions extends StatelessWidget {
  final OnlineOrder order;
  final bool actionLoading;
  final VoidCallback? onAccept;
  final VoidCallback? onCancel;

  const OnlineOrderDetailActions({
    super.key,
    required this.order,
    this.actionLoading = false,
    this.onAccept,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final canAccept = order.estado == 'PENDIENTE' && onAccept != null;
    final canCancel =
        !const ['ANULADO', 'ATENDIDO', 'FINALIZADO'].contains(order.estado) &&
        onCancel != null;
    if (!canAccept && !canCancel) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE6EAF2))),
        boxShadow: [
          BoxShadow(
            color: Color(0x14263238),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (canAccept)
            Expanded(
              child: OrderActionButton(
                icon: Icons.check_rounded,
                label: 'Aceptar',
                kind: OrderActionKind.primary,
                loading: actionLoading,
                onTap: actionLoading ? null : onAccept,
              ),
            ),
          if (canAccept && canCancel) const SizedBox(width: 10),
          if (canCancel)
            Expanded(
              child: OrderActionButton(
                icon: Icons.close_rounded,
                label: 'Anular',
                kind: OrderActionKind.danger,
                loading: actionLoading && !canAccept,
                onTap: actionLoading ? null : onCancel,
              ),
            ),
        ],
      ),
    );
  }
}
