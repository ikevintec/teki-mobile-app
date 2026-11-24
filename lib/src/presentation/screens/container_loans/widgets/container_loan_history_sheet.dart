import 'container_form_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/container_loan.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/container_loans/container_loans_provider.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';
import 'package:teki_app/src/utils/notifications.dart';

/// Historial de devoluciones de un préstamo, con opción de revertir.
class ContainerLoanHistorySheet extends ConsumerStatefulWidget {
  final ContainerLoan loan;

  const ContainerLoanHistorySheet({super.key, required this.loan});

  static Future<void> show(BuildContext context, ContainerLoan loan) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ContainerLoanHistorySheet(loan: loan),
    );
  }

  @override
  ConsumerState<ContainerLoanHistorySheet> createState() =>
      _ContainerLoanHistorySheetState();
}

class _ContainerLoanHistorySheetState
    extends ConsumerState<ContainerLoanHistorySheet> {
  late Future<List<ContainerReturn>> _history;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _history = ref.read(containerLoansProvider.notifier).history(widget.loan);
  }

  bool get _canReverse {
    final sesion = ref.read(sesionProvider);
    return sesion.hasPermission('INVENTARIO_AJUSTAR') ||
        sesion.hasPermission('SUPER_USUARIO');
  }

  Future<void> _reverse(ContainerReturn row) async {
    final qty = formatDouble(row.quantity);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Deshacer devolución'),
        content: Text(
          '${row.quantity == 1 ? 'Se retirará 1 envase vacío' : 'Se retirarán $qty envases vacíos'}'
          ' de ${row.office ?? 'la sede'} y volverá al saldo pendiente del cliente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deshacer devolución'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref.read(containerLoansProvider.notifier).reverse(widget.loan, row);
      if (!mounted) return;
      Navigator.of(context).pop();
      successNotification(
        'Devolución deshecha. Stock y pendientes actualizados.',
      );
    } catch (error) {
      if (mounted) setState(() => _saving = false);
      errorNotification(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ContainerSheetHeader(
                title: 'Historial de devoluciones',
                saving: _saving,
              ),
              Text(
                [
                  loan.customer,
                  loan.container,
                  loan.openingBalance ? 'Registro de pendientes' : loan.ticket,
                ].whereType<String>().join(' · '),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              if (loan.openingBalance && (loan.note?.isNotEmpty ?? false))
                Text(
                  'Observación del registro: ${loan.note}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              const SizedBox(height: 8),
              Flexible(
                child: FutureBuilder<List<ContainerReturn>>(
                  future: _history,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: ColorSchema.primaryColor,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No se pudo cargar el historial.'),
                      );
                    }
                    final rows = snapshot.data ?? const [];
                    if (rows.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Todavía no se han registrado devoluciones.',
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: rows.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final row = rows[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${formatDouble(row.quantity)} '
                            '${row.quantity == 1 ? 'envase' : 'envases'}'
                            ' · ${row.office ?? ''}',
                          ),
                          subtitle: Text(
                            [
                              if (row.createdOn != null)
                                DateFormat(
                                  'dd/MM/yyyy HH:mm',
                                ).format(row.createdOn!),
                              if (row.note?.isNotEmpty ?? false) row.note!,
                            ].join('\n'),
                          ),
                          trailing: row.cancelledOn != null
                              ? const Text(
                                  'Deshecha',
                                  style: TextStyle(color: Colors.grey),
                                )
                              : _canReverse
                              ? TextButton(
                                  onPressed: _saving
                                      ? null
                                      : () => _reverse(row),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Deshacer'),
                                )
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
