import 'container_form_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/container_loan.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/container_loans/container_loans_provider.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/notifications.dart';

/// Registra una devolución (parcial) de envases y la sede que los recibe.
class ContainerReturnSheet extends ConsumerStatefulWidget {
  final ContainerLoan loan;

  const ContainerReturnSheet({super.key, required this.loan});

  static Future<void> show(BuildContext context, ContainerLoan loan) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ContainerReturnSheet(loan: loan),
    );
  }

  @override
  ConsumerState<ContainerReturnSheet> createState() =>
      _ContainerReturnSheetState();
}

class _ContainerReturnSheetState extends ConsumerState<ContainerReturnSheet> {
  // Un id por apertura: reintentar tras un fallo no duplica el ingreso.
  final String _requestId = ContainerLoansNotifier.newRequestId();
  final TextEditingController _note = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  int get _quantity => int.tryParse(_quantityController.text) ?? 0;
  int? _officeId;
  bool _saving = false;

  int get _pending => widget.loan.pendingQuantity.toInt();

  @override
  void initState() {
    super.initState();
    _officeId = ref.read(sesionProvider).office?.id;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _note.dispose();
    super.dispose();
  }

  bool get _valid =>
      _officeId != null && _quantity > 0 && _quantity <= _pending;

  String? get _quantityError {
    if (_quantity < 1) return 'Ingresa al menos 1 envase.';
    if (_quantity > _pending) {
      return 'Solo hay $_pending envases por devolver.';
    }
    return null;
  }

  void _setQuantity(int value) {
    setState(() => _quantityController.text = value.toString());
  }

  Future<void> _submit() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);
    try {
      final loan = await ref
          .read(containerLoansProvider.notifier)
          .receive(
            widget.loan,
            ContainerReturn(
              quantity: _quantity.toDouble(),
              officeId: _officeId,
              requestId: _requestId,
              note: _note.text,
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      final pending = loan.pendingQuantity.toInt();
      successNotification(
        pending == 0
            ? 'Todos los envases fueron devueltos. Stock actualizado.'
            : 'Quedan $pending envases por devolver. Stock actualizado.',
      );
    } catch (error) {
      if (mounted) setState(() => _saving = false);
      errorNotification(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final offices = ref.watch(sesionProvider).offices ?? const [];
    final remaining = _pending - _quantity;
    return ContainerFormStyle(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ContainerSheetHeader(title: 'Recibir envases', saving: _saving),
                const SizedBox(height: 4),
                Text(
                  '${widget.loan.customer ?? ''}\n${widget.loan.container ?? ''} · '
                  '$_pending por devolver',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Quitar un envase',
                      onPressed: _saving || _quantity <= 1
                          ? null
                          : () => _setQuantity(_quantity - 1),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _quantityController,
                        enabled: !_saving,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        textAlign: TextAlign.center,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Cantidad recibida',
                          helperText:
                              'Hasta $_pending ${_pending == 1 ? 'envase' : 'envases'}',
                          errorText: _quantityError,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Agregar un envase',
                      onPressed: _saving || _quantity >= _pending
                          ? null
                          : () => _setQuantity(_quantity + 1),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: offices.any((o) => o.id == _officeId)
                      ? _officeId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Sede que los recibe',
                  ),
                  items: [
                    for (final office in offices)
                      DropdownMenuItem(
                        value: office.id,
                        child: Text(office.nombre ?? '-'),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (id) => setState(() => _officeId = id),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _note,
                  enabled: !_saving,
                  maxLength: 250,
                  decoration: const InputDecoration(
                    labelText: 'Observación (opcional)',
                  ),
                ),
                if (_quantityError == null)
                  remaining == 0
                      ? const Text(
                          'El cliente quedará sin envases pendientes.',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        )
                      : Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Envases que quedarán por devolver: ',
                              ),
                              TextSpan(
                                text:
                                    '$remaining ${remaining == 1 ? 'envase' : 'envases'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorSchema.primaryColor,
                    ),
                    onPressed: _valid && !_saving ? _submit : null,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Confirmar devolución'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
