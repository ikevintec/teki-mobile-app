import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail.dart';
import 'package:teki_app/src/providers/restaurant/qr_command_review_provider.dart';
import 'package:teki_app/src/utils/constants.dart';

class QrCommandReviewCard extends ConsumerWidget {
  final Command command;

  const QrCommandReviewCard({super.key, required this.command});

  String _timeLabel(BuildContext context) {
    final date = command.fecha;
    if (date == null) return '';
    return MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(date.toLocal()));
  }

  String _optionsSummary(CommandDetail item) {
    final options = <String>[
      ...(item.grupoProductoOpciones ?? const [])
          .where((option) => option.eliminado != true)
          .map((option) => option.nombreOpcion)
          .whereType<String>(),
      ...(item.preparacionProductoOpciones ?? const [])
          .map((option) => option.nombreOpcion)
          .whereType<String>(),
    ].where((value) => value.trim().isNotEmpty);
    return options.join(' · ');
  }

  bool _doesNotCharge(CommandDetail item) {
    final status = item.estadoComandaDetalle?.toUpperCase();
    return item.eliminado == true ||
        status == 'CANCELADO' ||
        status == 'RECHAZADO';
  }

  double get _total => (command.items ?? const [])
      .where((item) => !_doesNotCharge(item))
      .fold(
        0,
        (sum, item) => sum + (item.precioVenta ?? 0) * (item.cantidad ?? 0),
      );

  Future<void> _confirmReject(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rechazar comanda QR'),
        content: const Text(
          'Los productos se cancelarán y saldrán de la cuenta del comensal. '
          '¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Sí, rechazar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(qrCommandReviewProvider.notifier).reject(command);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final processingId = ref.watch(
      qrCommandReviewProvider.select((state) => state.processingCommandId),
    );
    final busy = processingId != null;
    final processingThis = processingId == command.id;
    final withoutWaiter = command.pedidoSinMozo == true;
    final table = command.pedido?.mesa;
    final tableLabel = table == null
        ? 'Sin mesa'
        : 'Mesa ${table.numero ?? table.id ?? '-'}';
    final commandNumber = command.numeroComanda ?? command.id ?? '-';
    final time = _timeLabel(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 10),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF7E6),
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.table_restaurant_rounded,
                  size: 19,
                  color: Color(0xFFB45309),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    tableLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF78350F),
                    ),
                  ),
                ),
                Text(
                  'Comanda #$commandNumber${time.isEmpty ? '' : ' · $time'}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(
              children: [
                for (final item in command.items ?? const <CommandDetail>[])
                  _QrCommandItem(
                    item: item,
                    optionsSummary: _optionsSummary(item),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${command.items?.length ?? 0} producto(s)',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                Text(
                  'S/ ${_total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: ColorSchema.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          if (!withoutWaiter)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.person_rounded,
                    size: 15,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Esta mesa ya tiene un mozo asignado.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: busy ? null : () => _confirmReject(context, ref),
                  icon: const Icon(Icons.close_rounded, size: 17),
                  label: const Text('Rechazar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () => ref
                            .read(qrCommandReviewProvider.notifier)
                            .approve(command),
                  icon: processingThis
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded, size: 17),
                  label: const Text('Aprobar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorSchema.primaryColor,
                    side: const BorderSide(color: ColorSchema.primaryColor),
                  ),
                ),
                if (withoutWaiter)
                  FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () => ref
                              .read(qrCommandReviewProvider.notifier)
                              .approve(command, attend: true),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
                    label: const Text('Aprobar y atender'),
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorSchema.primaryColor,
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

class _QrCommandItem extends StatelessWidget {
  final CommandDetail item;
  final String optionsSummary;

  const _QrCommandItem({required this.item, required this.optionsSummary});

  @override
  Widget build(BuildContext context) {
    final quantity = item.cantidad ?? 0;
    final quantityLabel = quantity == quantity.roundToDouble()
        ? quantity.toInt().toString()
        : quantity.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 30),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: ColorSchema.primaryColor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              '${quantityLabel}x',
              textAlign: TextAlign.center,
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
                  item.producto?.nombre ?? 'Producto',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (optionsSummary.isNotEmpty)
                  Text(
                    optionsSummary,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                if (item.nota?.trim().isNotEmpty == true)
                  Text(
                    item.nota!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFB45309),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                if (item.paraLlevar == true)
                  const Text(
                    'Para llevar',
                    style: TextStyle(
                      fontSize: 11,
                      color: ColorSchema.primaryColor,
                      fontWeight: FontWeight.w600,
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
