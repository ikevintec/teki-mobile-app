import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/cash_register_detail.dart';
import 'package:teki_app/src/data/models/teki_model/payment_detail.dart';
import 'package:teki_app/src/data/models/teki_model/purchase.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';

class CajaMovimientoScreen extends StatelessWidget {
  final CashRegisterDetail item;

  const CajaMovimientoScreen({super.key, required this.item});

  bool get _esIngreso => item.tipoMovimientoCaja == 'INGRESO';

  Color get _accentColor =>
      _esIngreso ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

  Color get _accentBg =>
      _esIngreso ? const Color(0xFFDCFCE7) : const Color(0xFFFFE4E6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      appBar: AppBar(
        title: Text(
          _esIngreso ? 'Detalle de Ingreso' : 'Detalle de Egreso',
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
        backgroundColor: _accentColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildResumenCard(),
            const SizedBox(height: 12),
            if (item.ticket != null) ...[
              _buildTicketCard(item.ticket!),
              const SizedBox(height: 12),
            ],
            if (item.compra != null) ...[
              _buildCompraCard(item.compra!),
              const SizedBox(height: 12),
            ],
            if (item.pagos != null && item.pagos!.isNotEmpty)
              _buildPagosCard(item.pagos!),
          ],
        ),
      ),
    );
  }

  // ── Resumen ──────────────────────────────────────────────────────────────

  Widget _buildResumenCard() {
    final symbol =
        formatExchange(moneda: item.monedaMovimientoCaja ?? 'PEN');
    final monto = item.monto ?? 0.0;
    final fecha = item.fechaMovimiento != null
        ? DateFormat('dd MMM yyyy — HH:mm', 'es')
            .format(item.fechaMovimiento!)
        : '-';
    final usuario = item.usuario?.nombreCompleto ?? '-';
    final concepto =
        item.conceptoMovimientoCaja?.replaceAll('_', ' ') ?? '-';

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tipo + monto
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _accentBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _esIngreso ? 'INGRESO' : 'EGRESO',
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _accentColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$symbol${monto.toStringAsFixed(2)}',
                style: GoogleFonts.roboto(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Divider(),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.description_outlined,
            label: 'Descripción',
            value: item.descripcion ?? '-',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.category_outlined,
            label: 'Concepto',
            value: concepto,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.access_time_rounded,
            label: 'Fecha',
            value: fecha,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Registrado por',
            value: usuario,
          ),
        ],
      ),
    );
  }

  // ── Ticket (Ingreso) ─────────────────────────────────────────────────────

  Widget _buildTicketCard(Ticket ticket) {
    final serieNum =
        '${ticket.serie ?? ''}-${ticket.numero?.toString() ?? ''}';
    final tipo = _labelTipoComprobante(ticket.tipoComprobante);
    final total = ticket.totalVenta;
    final symbol = formatExchange(moneda: ticket.codigoMoneda ?? 'PEN');

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.receipt_long_rounded,
            label: 'Comprobante de Venta',
            color: _accentColor,
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.tag_rounded,
            label: 'Serie / Número',
            value: serieNum,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.insert_drive_file_outlined,
            label: 'Tipo',
            value: tipo,
          ),
          if (ticket.tipoVenta != null) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.swap_horiz_rounded,
              label: 'Tipo de venta',
              value: ticket.tipoVenta!.replaceAll('_', ' '),
            ),
          ],
          if (ticket.codigoMoneda != null) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.attach_money_rounded,
              label: 'Moneda',
              value: ticket.codigoMoneda!,
            ),
          ],
          if (total != null) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.price_check_rounded,
              label: 'Total venta',
              value: '$symbol${total.toStringAsFixed(2)}',
              valueStyle: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _accentColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Compra (Egreso) ──────────────────────────────────────────────────────

  Widget _buildCompraCard(Purchase compra) {
    final symbol =
        formatExchange(moneda: compra.codigoMoneda ?? 'PEN');
    final total = compra.totalCompra ?? item.monto ?? 0.0;
    final fecha = compra.fecha != null
        ? DateFormat('dd MMM yyyy', 'es').format(compra.fecha!)
        : null;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.shopping_cart_outlined,
            label: 'Orden de Compra',
            color: _accentColor,
          ),
          const SizedBox(height: 14),
          if (compra.nombreProveedor != null) ...[
            _InfoRow(
              icon: Icons.storefront_outlined,
              label: 'Proveedor',
              value: compra.nombreProveedor!,
            ),
            const SizedBox(height: 10),
          ],
          if (compra.numeroDocumentoProveedor != null) ...[
            _InfoRow(
              icon: Icons.badge_outlined,
              label: 'Doc. proveedor',
              value: compra.numeroDocumentoProveedor!,
            ),
            const SizedBox(height: 10),
          ],
          if (compra.comprobante != null) ...[
            _InfoRow(
              icon: Icons.insert_drive_file_outlined,
              label: 'Comprobante',
              value: compra.comprobante!,
            ),
            const SizedBox(height: 10),
          ],
          if (compra.tipoCompra != null) ...[
            _InfoRow(
              icon: Icons.swap_horiz_rounded,
              label: 'Tipo de compra',
              value: compra.tipoCompra!.replaceAll('_', ' '),
            ),
            const SizedBox(height: 10),
          ],
          if (fecha != null) ...[
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Fecha',
              value: fecha,
            ),
            const SizedBox(height: 10),
          ],
          _InfoRow(
            icon: Icons.price_check_rounded,
            label: 'Total compra',
            value: '$symbol${total.toStringAsFixed(2)}',
            valueStyle: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _accentColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Pagos ────────────────────────────────────────────────────────────────

  Widget _buildPagosCard(List<PaymentDetail> pagos) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.payments_rounded,
            label: 'Formas de pago',
            color: ColorSchema.primaryColor,
          ),
          const SizedBox(height: 14),
          ...pagos.map((p) => _PagoItem(pago: p)),
        ],
      ),
    );
  }

  // ── Helper ───────────────────────────────────────────────────────────────

  String _labelTipoComprobante(String? tipo) {
    switch (tipo) {
      case '01':
        return 'Factura';
      case '03':
        return 'Boleta';
      case '07':
        return 'Nota de Crédito';
      case '08':
        return 'Nota de Débito';
      case 'NV':
        return 'Nota de Venta';
      default:
        return tipo ?? '-';
    }
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey.shade100,
      );
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionHeader(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.raleway(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F1F1F),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: valueStyle ??
                    GoogleFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F1F1F),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PagoItem extends StatelessWidget {
  final PaymentDetail pago;
  const _PagoItem({required this.pago});

  IconData _iconForFormaPago(String? forma) {
    switch (forma) {
      case 'EFECTIVO':
        return Icons.payments_rounded;
      case 'TARJETA':
        return Icons.credit_card_rounded;
      case 'TRANSFERENCIA':
        return Icons.account_balance_rounded;
      case 'CHEQUE':
        return Icons.receipt_long_rounded;
      default:
        return Icons.attach_money_rounded;
    }
  }

  Color _colorForFormaPago(String? forma) {
    switch (forma) {
      case 'EFECTIVO':
        return const Color(0xFF16A34A);
      case 'TARJETA':
        return ColorSchema.primaryColor;
      case 'TRANSFERENCIA':
        return const Color(0xFF7C3AED);
      case 'CHEQUE':
        return const Color(0xFFD97706);
      default:
        return Colors.grey.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final forma = pago.formaPago;
    final color = _colorForFormaPago(forma);
    final icon = _iconForFormaPago(forma);
    final nombre = pago.nombre ?? pago.formaPago ?? '-';
    final detalle = pago.tipoTarjeta != null ? '  ·  ${pago.tipoTarjeta}' : '';
    final symbol =
        formatExchange(moneda: pago.metodoPago?.formaPago == null ? 'PEN' : 'PEN');
    final monto = pago.monto ?? 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$nombre$detalle',
              style: GoogleFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F1F1F),
              ),
            ),
          ),
          Text(
            '$symbol${monto.toStringAsFixed(2)}',
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
