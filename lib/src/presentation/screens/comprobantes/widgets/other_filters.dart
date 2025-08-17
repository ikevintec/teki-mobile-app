import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/selector/multi_selector.dart';
import 'package:teki_app/src/presentation/widgets/segment/custom_segment_selector.dart';
import 'package:teki_app/src/utils/contstants.dart';

class OtherFilters extends StatefulWidget {
  final Function(Map<String, dynamic>)? onFiltersChanged;
  
  const OtherFilters({
    super.key,
    this.onFiltersChanged,
  });

  @override
  State<OtherFilters> createState() => _OtherFiltersState();
}

class _OtherFiltersState extends State<OtherFilters> {
  final TextEditingController _serieController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  
  List<String> _selectedPaymentMethods = [];
  List<String> _selectedDocumentTypes = [];
  String _selectedStatus = 'Todos';

  // Datos para los selectores múltiples
  final List<Map<String, String>> _paymentMethods = [
    {'label': 'Efectivo', 'value': 'EFECTIVO'},
    {'label': 'Tarjeta de Crédito', 'value': 'TARJETA_CREDITO'},
    {'label': 'Tarjeta de Débito', 'value': 'TARJETA_DEBITO'},
    {'label': 'Transferencia', 'value': 'TRANSFERENCIA'},
    {'label': 'Yape', 'value': 'YAPE'},
    {'label': 'Plin', 'value': 'PLIN'},
    {'label': 'BIM', 'value': 'BIM'},
    {'label': 'Cheque', 'value': 'CHEQUE'},
    {'label': 'Depósito en Cuenta', 'value': 'DEPOSITO'},
  ];

  final List<Map<String, String>> _documentTypes = [
    {'label': 'Boleta de Venta', 'value': 'BOLETA'},
    {'label': 'Factura', 'value': 'FACTURA'},
    {'label': 'Nota de Crédito', 'value': 'NOTA_CREDITO'},
    {'label': 'Nota de Débito', 'value': 'NOTA_DEBITO'},
    {'label': 'Guía de Remisión', 'value': 'GUIA_REMISION'},
    {'label': 'Recibo por Honorarios', 'value': 'RECIBO_HONORARIOS'},
  ];

  final List<String> _statusOptions = ['Todos', 'Activos', 'Anulados'];

  @override
  void dispose() {
    _serieController.dispose();
    _numeroController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    final filters = {
      'serie': _serieController.text.trim(),
      'numero': _numeroController.text.trim(),
      'paymentMethods': _selectedPaymentMethods,
      'documentTypes': _selectedDocumentTypes,
      'status': _selectedStatus,
    };
    widget.onFiltersChanged?.call(filters);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primera fila: Serie y Número
          Row(
            children: [
              Expanded(
                child: TextFieldSection(
                  label: 'Serie',
                  hint: 'Ej. F001, B001',
                  inputType: TextInputType.text,
                  controller: _serieController,
                  onChanged: (_) => _onFilterChanged(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFieldSection(
                  label: 'Número',
                  hint: 'Ej. 000123',
                  inputType: TextInputType.number,
                  controller: _numeroController,
                  onChanged: (_) => _onFilterChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Segunda fila: Métodos de Pago
          MultiSelector(
            label: 'Métodos de Pago',
            hint: 'Selecciona métodos de pago',
            options: _paymentMethods,
            selectedValues: _selectedPaymentMethods,
            onChanged: (values) {
              setState(() {
                _selectedPaymentMethods = values;
              });
              _onFilterChanged();
            },
          ),
          const SizedBox(height: 16),

          // Tercera fila: Tipos de Comprobantes
          MultiSelector(
            label: 'Tipos de Comprobantes',
            hint: 'Selecciona tipos de documentos',
            options: _documentTypes,
            selectedValues: _selectedDocumentTypes,
            onChanged: (values) {
              setState(() {
                _selectedDocumentTypes = values;
              });
              _onFilterChanged();
            },
          ),
          const SizedBox(height: 20),

          // Cuarta fila: Estado (Segment Selector)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estado',
                style: GoogleFonts.raleway(
                  color: const Color(0xFF444444),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              CustomSegmentedSelector(
                label: 'Estado',
                options: _statusOptions,
                selected: _selectedStatus,
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                  _onFilterChanged();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Botón de Aplicar Filtros
          Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              ),
              child: Text(
              'Volver',
              style: GoogleFonts.nunito(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              ),
            ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
              onPressed: _onFilterChanged,
              style: ElevatedButton.styleFrom(
              backgroundColor: ColorSchema.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              ),
              child: Text(
              'Aplicar',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              ),
            ),
            ),
          ],
          ),
            
        ],
      ),
    );
  }
}