import 'package:flutter/material.dart';
import 'package:teki_app/src/data/models/teki_model/customer.dart';
import 'package:teki_app/src/data/models/teki_model/delivery.dart';
import 'package:teki_app/src/utils/constants.dart';

// ─── Order info row ───────────────────────────────────────────────────────────

class OrderInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBadge;

  const OrderInfoRow({
    super.key,
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
class StackedInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value1;
  final String? value2;

  const StackedInfoRow({
    super.key,
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
class LabeledInfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? trailing;

  const LabeledInfoCard({super.key, required this.title, required this.children, this.trailing});

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
class ClienteInfoCard extends StatelessWidget {
  final Customer? cliente;

  const ClienteInfoCard({super.key, required this.cliente});

  @override
  Widget build(BuildContext context) {
    final nombre = cliente?.razonSocial?.isNotEmpty == true ? cliente!.razonSocial! : null;
    final telefono = cliente?.telefono?.isNotEmpty == true ? cliente!.telefono! : null;
    if (nombre == null && telefono == null) return const SizedBox.shrink();
    return LabeledInfoCard(
      title: 'Cliente',
      children: [
        if (nombre != null)
          OrderInfoRow(icon: Icons.person_outline_rounded, label: 'Nombre', value: nombre),
        if (telefono != null)
          OrderInfoRow(icon: Icons.phone_outlined, label: 'Teléfono', value: telefono),
      ],
    );
  }
}

/// Card with address info, shown only when at least one field has data.
class DireccionInfoCard extends StatelessWidget {
  final String? direccionCompleta;
  final String? referencia;
  final double? montoDelivery;

  const DireccionInfoCard({
    super.key,
    this.direccionCompleta,
    this.referencia,
    this.montoDelivery,
  });

  /// El backend concatena campos que pueden venir null y entrega strings
  /// como "null null": se tratan como vacío.
  static String? _sanitize(String? value) {
    if (value == null) return null;
    final limpio = value
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty && t.toLowerCase() != 'null')
        .join(' ')
        .trim();
    return limpio.isEmpty ? null : limpio;
  }

  @override
  Widget build(BuildContext context) {
    final dir = _sanitize(direccionCompleta);
    final ref = _sanitize(referencia);
    final monto = (montoDelivery != null && montoDelivery! > 0) ? montoDelivery : null;
    if (dir == null && ref == null && monto == null) return const SizedBox.shrink();
    return LabeledInfoCard(
      title: 'Dirección',
      children: [
        if (dir != null)
          OrderInfoRow(icon: Icons.location_on_outlined, label: 'Dirección', value: dir),
        if (ref != null)
          OrderInfoRow(icon: Icons.signpost_outlined, label: 'Referencia', value: ref),
        if (monto != null)
          OrderInfoRow(
            icon: Icons.delivery_dining_outlined,
            label: 'Costo delivery',
            value: 'S/. ${monto.toStringAsFixed(2)}',
          ),
      ],
    );
  }
}

/// Card with online order info, shown only when at least one field has data.
class OnlineInfoCard extends StatelessWidget {
  final String? estadoOnline;
  final String? formaPago;
  final String? nombreFormaPago;
  final Delivery? envio;

  const OnlineInfoCard({
    super.key,
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
    return LabeledInfoCard(
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
          OrderInfoRow(
            icon: Icons.delivery_dining_outlined,
            label: 'Estado envío',
            value: estadoEnvio,
            valueColor: _estadoDeliveryColor(estadoEnvio),
            valueBadge: true,
          ),
        if (repartidor != null)
          OrderInfoRow(icon: Icons.person_pin_circle_outlined, label: 'Repartidor', value: repartidor),
        if (fpCodigo != null || fpNombre != null)
          StackedInfoRow(
            icon: Icons.payment_outlined,
            label: 'Forma de pago',
            value1: fpCodigo ?? fpNombre!,
            value2: fpCodigo != null ? fpNombre : null,
          ),
      ],
    );
  }
}
