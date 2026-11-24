import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/providers/comprobantes/comprobante.dart';
import 'package:teki_app/src/utils/notifications.dart';

/// Formulario para anular un comprobante indicando el motivo.
class FormAnularComprobante extends ConsumerStatefulWidget {
  final Ticket ticket;

  /// Callback opcional que se ejecuta luego de anular con éxito (por ejemplo,
  /// para refrescar el listado de comprobantes).
  final VoidCallback? onSuccess;

  const FormAnularComprobante({super.key, required this.ticket, this.onSuccess});

  @override
  ConsumerState<FormAnularComprobante> createState() =>
      _FormAnularComprobanteState();
}

class _FormAnularComprobanteState extends ConsumerState<FormAnularComprobante> {
  final TextEditingController _motivoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  String? _validateMotivo(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa el motivo de la anulación';
    }
    if (value.trim().length < 3) {
      return 'El motivo debe tener al menos 3 caracteres';
    }
    return null;
  }

  Future<void> _anular() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(comprobanteProvider.notifier)
          .anularComprobante(widget.ticket, _motivoController.text.trim());

      if (!mounted) return;
      Navigator.of(context).pop();
      successNotification('Comprobante anulado correctamente');
      widget.onSuccess?.call();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        errorNotification('No se pudo anular el comprobante: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header icon
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.only(bottom: 5),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.block,
                size: 32,
                color: Colors.red,
              ),
            ),
          ),

          // Motivo Field
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                TextFormField(
                  controller: _motivoController,
                  keyboardType: TextInputType.multiline,
                  maxLines: 3,
                  minLines: 2,
                  maxLength: 250,
                  validator: _validateMotivo,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Motivo de la anulación',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons Row
          Container(
            height: 50,
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                // Cancel Button (30%)
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                    ),
                    child: Text(
                      'Volver',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Anular Button (70%)
                Expanded(
                  flex: 7,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _anular,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.block, size: 18),
                    label: Text(
                      _isLoading ? 'Anulando...' : 'Anular',
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Esta acción anulará el comprobante y no se puede deshacer.',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w400,
                    ),
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
