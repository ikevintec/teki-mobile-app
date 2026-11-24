import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/providers/whatsapp/whatsapp_provider.dart';
import 'package:teki_app/src/utils/notifications.dart';

/// Datos mínimos que necesita el formulario para enviar el documento por
/// WhatsApp, desacoplado del modelo de origen (Ticket o Quotation).
class WhatsappSendData {
  final String? initialPhone;
  final String message;
  final String filename;
  final String documentUrl;

  const WhatsappSendData({
    this.initialPhone,
    required this.message,
    required this.filename,
    required this.documentUrl,
  });
}

class FormSendWhatsapp extends ConsumerStatefulWidget {
  final WhatsappSendData data;

  const FormSendWhatsapp({
    super.key,
    required this.data,
  });

  @override
  ConsumerState<FormSendWhatsapp> createState() => _FormSendWhatsappState();
}

class _FormSendWhatsappState extends ConsumerState<FormSendWhatsapp> {
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  /// Código de país (Perú).
  static const String _countryCode = '51';

  void _initializeForm() {
    if (widget.data.initialPhone?.isNotEmpty == true) {
      // Mostramos solo el número local, sin el código de país.
      _phoneController.text = _extractLocalNumber(widget.data.initialPhone!);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// Sanitiza la entrada: elimina cualquier carácter no numérico y, si el
  /// número incluye el código de país (`+51` / `51`), lo remueve para quedarnos
  /// solo con el número local.
  String _extractLocalNumber(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length > 9 && digits.startsWith(_countryCode)) {
      digits = digits.substring(_countryCode.length);
    }
    return digits;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa un número de teléfono';
    }

    final localNumber = _extractLocalNumber(value);
    if (localNumber.length != 9) {
      return 'El número debe tener 9 dígitos';
    }

    return null;
  }


  Future<void> _sendWhatsApp() async {
    if (!_formKey.currentState!.validate()) return;
    
    Navigator.of(context).pop();
    
    // Ejecutar el envío en background
    _sendWhatsAppInBackground();
  }

  void _sendWhatsAppInBackground() async {
    try {
      final whatsappNotifier = ref.read(whatsappProvider.notifier);

      // Enviamos el número con el código de país al endpoint.
      final phoneNumber =
          '$_countryCode${_extractLocalNumber(_phoneController.text)}';

      final response = await whatsappNotifier.sendWhatsapp(
        phoneNumber: phoneNumber,
        message: widget.data.message,
        filename: widget.data.filename,
        documentUrl: widget.data.documentUrl,
      );
        if (response.success) {
          successNotification(response.message ?? 'Mensaje enviado correctamente');
        } else {
          errorNotification(response.message ?? 'Error al enviar mensaje');
        }
    } catch (e) {
        errorNotification('Error inesperado: ${e.toString()}');
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
          // WhatsApp Icon Header
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.only(bottom: 5),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat,
                size: 32,
                color: Color(0xFF25D366),
              ),
            ),
          ),
          
          // Phone Number Field
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  validator: _validatePhone,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Número de teléfono',
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
                      borderSide: const BorderSide(color: Color(0xFF25D366), width: 2),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
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
                
                // Send Button (70%)
                Expanded(
                  flex: 7,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _sendWhatsApp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: const Color(0xFF25D366).withOpacity(0.3),
                    ),
                    icon: _isLoading 
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send, size: 18),
                    label: Text(
                      _isLoading ? 'Enviando...' : 'Enviar',
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
                    'Se enviará el recibo vía WhatsApp al número proporcionado.',
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