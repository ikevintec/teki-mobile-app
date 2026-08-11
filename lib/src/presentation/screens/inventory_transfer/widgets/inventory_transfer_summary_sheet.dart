import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/inventory_transfer.dart';
import 'package:teki_app/src/data/models/teki_model/inventory_transfer_detail.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';
import 'package:teki_app/src/utils/notifications.dart';
import 'package:url_launcher/url_launcher.dart';

class InventoryTransferSummarySheet extends StatefulWidget {
  final InventoryTransfer transfer;

  const InventoryTransferSummarySheet({super.key, required this.transfer});

  static Future<void> show(BuildContext context, InventoryTransfer transfer) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InventoryTransferSummarySheet(transfer: transfer),
    );
  }

  @override
  State<InventoryTransferSummarySheet> createState() =>
      _InventoryTransferSummarySheetState();
}

class _InventoryTransferSummarySheetState
    extends State<InventoryTransferSummarySheet> {
  bool _isOpeningPdf = false;

  InventoryTransfer get transfer => widget.transfer;

  Future<void> _downloadPdf() async {
    final uuid = transfer.uuid?.trim();
    if (uuid == null || uuid.isEmpty) {
      warningNotification('Este traslado no tiene un archivo disponible');
      return;
    }

    setState(() => _isOpeningPdf = true);
    try {
      final baseUrl = Environment.apiUrl.endsWith('/')
          ? Environment.apiUrl.substring(0, Environment.apiUrl.length - 1)
          : Environment.apiUrl;
      final uri = Uri.parse('$baseUrl/public/pdf/inventory-transfer/$uuid.pdf');
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        errorNotification('No se pudo abrir el archivo del traslado');
      }
    } catch (_) {
      errorNotification('No se pudo descargar el archivo del traslado');
    } finally {
      if (mounted) setState(() => _isOpeningPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(transfer.estadoTraslado);

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Material(
        color: const Color(0xFFF5F6FA),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _SheetHeader(
              transferId: transfer.id,
              status: transfer.estadoTraslado,
              statusColor: statusColor,
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TransferRouteCard(transfer: transfer),
                    const SizedBox(height: 18),
                    const _SectionTitle(
                      icon: Icons.history_rounded,
                      text: 'Seguimiento',
                    ),
                    const SizedBox(height: 10),
                    _TransferStageCard(
                      title: 'Solicitud',
                      icon: Icons.outbox_outlined,
                      color: const Color(0xFFB7791F),
                      user: transfer.usuarioSolicitud,
                      date: transfer.fechaSolicitud,
                      description: transfer.comentarioSolicitud,
                    ),
                    const SizedBox(height: 9),
                    _TransferStageCard(
                      title: 'Atenci\u00f3n',
                      icon: Icons.inventory_outlined,
                      color: const Color(0xFF2768B2),
                      user: transfer.usuarioAtencion,
                      date: transfer.fechaAtencion,
                      description: transfer.comentarioAtencion,
                    ),
                    const SizedBox(height: 9),
                    _TransferStageCard(
                      title: 'Recepci\u00f3n',
                      icon: Icons.inventory_2_outlined,
                      color: const Color(0xFF26845B),
                      user: transfer.usuarioRecepcion,
                      date: transfer.fechaRecepcion,
                      description: transfer.comentarioRecepcion,
                    ),
                    const SizedBox(height: 18),
                    _SectionTitle(
                      icon: Icons.list_alt_rounded,
                      text: 'Productos (${transfer.items.length})',
                    ),
                    const SizedBox(height: 10),
                    if (transfer.items.isEmpty)
                      const _EmptyItemsCard()
                    else
                      ...transfer.items.indexed.map(
                        (entry) => Padding(
                          padding: EdgeInsets.only(
                            bottom: entry.$1 == transfer.items.length - 1
                                ? 0
                                : 9,
                          ),
                          child: _TransferItemCard(
                            index: entry.$1 + 1,
                            item: entry.$2,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: FilledButton.icon(
                  onPressed: _isOpeningPdf ? null : _downloadPdf,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: ColorSchema.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  icon: _isOpeningPdf
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_rounded),
                  label: Text(
                    _isOpeningPdf ? 'Abriendo archivo...' : 'Descargar PDF',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final int? transferId;
  final String? status;
  final Color statusColor;
  final VoidCallback onClose;

  const _SheetHeader({
    required this.transferId,
    required this.status,
    required this.statusColor,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 13),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen del traslado',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '#${transferId ?? '-'}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF27293D),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  normalizeEnumLabel(status),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Cerrar',
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransferRouteCard extends StatelessWidget {
  final InventoryTransfer transfer;

  const _TransferRouteCard({required this.transfer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _OfficeSummary(
              label: 'Origen',
              name: transfer.puntoVentaOrigen?.nombre ?? 'Sin origen',
              icon: Icons.storefront_outlined,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: ColorSchema.primaryColor.withValues(alpha: 0.09),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              size: 19,
              color: ColorSchema.primaryColor,
            ),
          ),
          Expanded(
            child: _OfficeSummary(
              label: 'Destino',
              name: transfer.puntoVentaDestino?.nombre ?? 'Sin destino',
              icon: Icons.store_rounded,
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfficeSummary extends StatelessWidget {
  final String label;
  final String name;
  final IconData icon;
  final bool alignEnd;

  const _OfficeSummary({
    required this.label,
    required this.name,
    required this.icon,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: alignEnd
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: Colors.black45),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.black45),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: const TextStyle(
            fontSize: 13,
            height: 1.25,
            fontWeight: FontWeight.w800,
            color: Color(0xFF34364A),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SectionTitle({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: ColorSchema.primaryColor),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Color(0xFF27293D),
          ),
        ),
      ],
    );
  }
}

class _TransferStageCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final User? user;
  final DateTime? date;
  final String? description;

  const _TransferStageCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.user,
    required this.date,
    required this.description,
  });

  bool get _hasData =>
      user != null || date != null || (description?.trim().isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF34364A),
                        ),
                      ),
                    ),
                    if (!_hasData)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Pendiente',
                          style: TextStyle(fontSize: 10, color: Colors.black45),
                        ),
                      ),
                  ],
                ),
                if (_hasData) ...[
                  const SizedBox(height: 7),
                  _StageInfoRow(
                    icon: Icons.person_outline_rounded,
                    text: _userName(user),
                  ),
                  const SizedBox(height: 4),
                  _StageInfoRow(
                    icon: Icons.schedule_rounded,
                    text: _dateLabel(date),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Descripci\u00f3n',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _descriptionLabel(description),
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: Color(0xFF4C4E60),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StageInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _StageInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}

class _TransferItemCard extends StatelessWidget {
  final int index;
  final InventoryTransferDetail item;

  const _TransferItemCard({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    final product = item.producto;
    final code = product?.codigo?.trim();
    final unit = product?.unidad?.abreviatura?.trim();

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 27,
                height: 27,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ColorSchema.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: ColorSchema.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product?.nombre?.trim().isNotEmpty == true
                          ? product!.nombre!.trim()
                          : 'Producto sin nombre',
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF34364A),
                      ),
                    ),
                    if (code != null && code.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'C\u00f3digo: $code',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuantitySummary(
                  label: 'Solicitada',
                  value: _quantityLabel(item.cantidadSolicitud, unit),
                  color: const Color(0xFFB7791F),
                ),
              ),
              _VerticalDivider(),
              Expanded(
                child: _QuantitySummary(
                  label: 'Atendida',
                  value: _quantityLabel(item.cantidadAtencion, unit),
                  color: const Color(0xFF2768B2),
                ),
              ),
              _VerticalDivider(),
              Expanded(
                child: _QuantitySummary(
                  label: 'Recibida',
                  value: _quantityLabel(item.cantidadRecepcion, unit),
                  color: const Color(0xFF26845B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantitySummary extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _QuantitySummary({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.black45)),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      color: Colors.grey.shade200,
    );
  }
}

class _EmptyItemsCard extends StatelessWidget {
  const _EmptyItemsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Text(
        'No se encontraron productos en este traslado.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: Colors.black45),
      ),
    );
  }
}

String _userName(User? user) {
  final options = [user?.nombreCompleto, user?.name, user?.username];
  for (final option in options) {
    if (option?.trim().isNotEmpty == true) return option!.trim();
  }
  return 'Usuario no registrado';
}

String _dateLabel(DateTime? date) {
  if (date == null) return 'Fecha no registrada';
  return DateFormat('dd/MM/yyyy, HH:mm').format(date.toLocal());
}

String _descriptionLabel(String? description) {
  final value = description?.trim();
  return value == null || value.isEmpty ? 'Sin descripci\u00f3n' : value;
}

String _quantityLabel(double? quantity, String? unit) {
  if (quantity == null) return '\u2014';
  final value = formatDouble(quantity);
  return unit == null || unit.isEmpty ? value : '$value $unit';
}

Color _statusColor(String? status) {
  switch (status) {
    case 'RECEPCIONADO':
      return const Color(0xFF26845B);
    case 'ATENDIDO':
      return const Color(0xFF2768B2);
    case 'ANULADO':
      return const Color(0xFFC33B43);
    case 'SOLICITADO':
    default:
      return const Color(0xFFB7791F);
  }
}
