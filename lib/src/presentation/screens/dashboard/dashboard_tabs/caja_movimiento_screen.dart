import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/cash_register_detail.dart';
import 'package:teki_app/src/data/models/teki_model/payment_detail.dart';
import 'package:teki_app/src/data/models/teki_model/payment_method.dart';
import 'package:teki_app/src/data/models/teki_model/purchase.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/repositories/ticket_sale_repository_impl.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/notifications.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';

class CajaMovimientoScreen extends ConsumerStatefulWidget {
  final CashRegisterDetail item;

  const CajaMovimientoScreen({super.key, required this.item});

  @override
  ConsumerState<CajaMovimientoScreen> createState() =>
      _CajaMovimientoScreenState();
}

class _CajaMovimientoScreenState extends ConsumerState<CajaMovimientoScreen> {
  CashRegisterDetail get item => widget.item;

  /// Pagos mostrados: parten del movimiento y se actualizan en memoria
  /// cuando se cambia el método de pago.
  late List<PaymentDetail> _pagos = item.pagos ?? [];

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
            if (_pagos.isNotEmpty) _buildPagosCard(_pagos),
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
    // Cambiar método de pago: solo ventas contado (ingreso con ticket) y con
    // el mismo permiso que la web.
    final puedeCambiar = item.ticket?.id != null &&
        _esIngreso &&
        item.ticket?.tipoVenta == 'CONTADO' &&
        ref.watch(sesionProvider).hasPermission('EDITAR_METODO_PAGO');
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SectionHeader(
                  icon: Icons.payments_rounded,
                  label: 'Formas de pago',
                  color: ColorSchema.primaryColor,
                ),
              ),
              if (puedeCambiar)
                TextButton.icon(
                  onPressed: _cambiarMetodoPago,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: const Text('Cambiar', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: ColorSchema.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ...pagos.map((p) => _PagoItem(pago: p)),
        ],
      ),
    );
  }

  /// Sheet de pagos mixtos: varios métodos con montos que deben sumar
  /// EXACTO el total de la venta (misma validación totalFormaPago de la web).
  /// Espeja PATCH /tickets/{id}/movimiento-caja.
  Future<void> _cambiarMetodoPago() async {
    final ticket = item.ticket!;
    final total = ticket.totalVenta ?? item.monto ?? 0;
    final metodos = (ref.read(sesionProvider).config?.formasPago ?? [])
        .where((m) => m.tipoMovimiento == null || m.tipoMovimiento == 'INGRESO')
        .toList();
    if (metodos.isEmpty) {
      warningNotification('No hay métodos de pago configurados', fromTop: false);
      return;
    }

    final pagos = await showModalBottomSheet<List<PaymentDetail>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _CambiarMetodoPagoSheet(
        titulo: '${ticket.serie ?? ''}-${ticket.numero ?? ''}',
        total: total,
        metodos: metodos,
      ),
    );
    if (pagos == null || pagos.isEmpty) return;

    try {
      await TicketSaleRepositoryImpl().updateMetodoPago(ticket.id!, {
        'pagos': [
          for (final p in pagos)
            {
              'metodoPago': {'id': p.metodoPago?.id},
              'formaPago': p.formaPago,
              'nombre': p.nombre,
              'tipoTarjeta': p.tipoTarjeta,
              'monto': p.monto,
              'montoPagado': p.montoPagado,
            }
        ],
        'tipoMovimientoCaja': 'INGRESO',
        'conceptoMovimientoCaja': 'VENTAS',
        'monedaMovimientoCaja': ticket.codigoMoneda ?? 'PEN',
        'monto': total,
      });
      if (!mounted) return;
      setState(() => _pagos = pagos);
      successNotification('Método de pago actualizado', fromTop: false);
    } catch (e) {
      errorNotification(e.toString(), fromTop: false);
    }
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

// ─── Sheet de cambio de método de pago (pagos mixtos) ─────────────────────────

class _CambiarMetodoPagoSheet extends StatefulWidget {
  final String titulo;
  final double total;
  final List<PaymentMethod> metodos;

  const _CambiarMetodoPagoSheet({
    required this.titulo,
    required this.total,
    required this.metodos,
  });

  @override
  State<_CambiarMetodoPagoSheet> createState() =>
      _CambiarMetodoPagoSheetState();
}

class _PagoEntry {
  PaymentMethod metodo;
  final TextEditingController controller;
  _PagoEntry(this.metodo, double monto)
      : controller = TextEditingController(
            text: monto > 0 ? monto.toStringAsFixed(2) : '');
}

class _CambiarMetodoPagoSheetState extends State<_CambiarMetodoPagoSheet> {
  late final List<_PagoEntry> _entries = [
    // Arranca con el primer método cubriendo el total (caso común: un método).
    _PagoEntry(widget.metodos.first, widget.total),
  ];

  @override
  void dispose() {
    for (final e in _entries) {
      e.controller.dispose();
    }
    super.dispose();
  }

  double get _asignado => _entries.fold(
      0.0, (s, e) => s + (double.tryParse(e.controller.text) ?? 0));

  /// La suma debe ser EXACTA al total (tolerancia de céntimo por redondeo).
  bool get _sumaExacta => (_asignado - widget.total).abs() < 0.01;

  void _agregarEntry() {
    // Sugiere el primer método no usado y precarga el monto faltante.
    final usados = _entries.map((e) => e.metodo.id).toSet();
    final libre = widget.metodos.firstWhere(
      (m) => !usados.contains(m.id),
      orElse: () => widget.metodos.first,
    );
    final faltante = (widget.total - _asignado).clamp(0.0, widget.total);
    setState(() => _entries.add(_PagoEntry(libre, faltante)));
  }

  void _confirmar() {
    final pagos = <PaymentDetail>[
      for (final e in _entries)
        if ((double.tryParse(e.controller.text) ?? 0) > 0)
          PaymentDetail(
            metodoPago: e.metodo,
            formaPago: e.metodo.formaPago,
            nombre: e.metodo.nombre,
            tipoTarjeta: e.metodo.tipoTarjeta,
            monto: double.parse(e.controller.text),
            montoPagado: double.parse(e.controller.text),
          ),
    ];
    Navigator.of(context).pop(pagos);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
              const SizedBox(height: 12),
              Text('Cambiar método de pago',
                  style: GoogleFonts.raleway(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              Text(
                '${widget.titulo} · total S/. ${widget.total.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 12),
              // Entradas de pago (método + monto)
              ...List.generate(_entries.length, (i) {
                final e = _entries[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<int>(
                          initialValue: e.metodo.id,
                          isDense: true,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          items: [
                            for (final m in widget.metodos)
                              DropdownMenuItem<int>(
                                value: m.id,
                                child: Text(m.nombre ?? '-',
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis),
                              ),
                          ],
                          onChanged: (id) {
                            setState(() => e.metodo = widget.metodos
                                .firstWhere((m) => m.id == id));
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: e.controller,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]')),
                          ],
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            prefixText: 'S/. ',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      if (_entries.length > 1)
                        IconButton(
                          icon: Icon(Icons.close,
                              size: 18, color: Colors.red.shade400),
                          onPressed: () => setState(() {
                            _entries.removeAt(i).controller.dispose();
                          }),
                        ),
                    ],
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed:
                      _entries.length < widget.metodos.length ? _agregarEntry : null,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Agregar método',
                      style: TextStyle(fontSize: 12.5)),
                ),
              ),
              const SizedBox(height: 4),
              // Resumen asignado vs total
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _sumaExacta
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _sumaExacta
                      ? 'Asignado S/. ${_asignado.toStringAsFixed(2)} ✓'
                      : 'Asignado S/. ${_asignado.toStringAsFixed(2)} de S/. ${widget.total.toStringAsFixed(2)} · '
                          '${_asignado < widget.total ? 'faltan' : 'sobran'} S/. ${(_asignado - widget.total).abs().toStringAsFixed(2)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _sumaExacta
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE65100),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sumaExacta ? _confirmar : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorSchema.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
