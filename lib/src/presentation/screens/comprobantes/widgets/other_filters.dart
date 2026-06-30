import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/selector/multi_selector.dart';
import 'package:teki_app/src/presentation/widgets/segment/custom_segment_selector.dart';
import 'package:teki_app/src/providers/comprobantes/comprobantes_notifier.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/contstants.dart';

class OtherFilters extends ConsumerStatefulWidget {
  final VoidCallback? onApplyFilters;
  
  const OtherFilters({
    super.key,
    this.onApplyFilters,
  });

  @override
  ConsumerState<OtherFilters> createState() => _OtherFiltersState();
}

class _OtherFiltersState extends ConsumerState<OtherFilters> {
  final TextEditingController _serieController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  
  List<String> _selectedPaymentMethods = [];
  List<String> _selectedDocumentTypes = [];
  String _selectedStatus = 'Todos';
  List<Map<String, String>> _paymentMethods = [];

  final List<Map<String, String>> _documentTypes = [
    {'label': 'Boleta de Venta', 'value': '03'},
    {'label': 'Factura', 'value': '01'},
    {'label': 'Nota de Crédito', 'value': '07'},
    {'label': 'Nota de Débito', 'value': '08'},
    {'label': 'Nota de venta', 'value': 'NV'},
  ];

  final List<String> _statusOptions = ['Todos', 'Activos', 'Anulados'];

  @override
  void initState() {
    super.initState();
    // Inicializar con los valores del provider en el próximo frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPaymentMethods();
      _loadFiltersFromProvider();
    });
  }

  @override
  void dispose() {
    _serieController.dispose();
    _numeroController.dispose();
    super.dispose();
  }

  void _loadPaymentMethods() {
    final sesionState = ref.read(sesionProvider);
    final configCompany = sesionState.config;
    
    if (configCompany?.formasPago != null) {
      setState(() {
        _paymentMethods = configCompany!.formasPago!
            .where((fp) => 
                (fp.formaPago == 'EFECTIVO' || fp.tipoMovimiento == 'INGRESO'))
            .map((fp) => {
                'label': fp.nombre ?? '',
                'value': fp.id?.toString() ?? ''
            })
            .toList();
      });
    }
  }

  void _loadFiltersFromProvider() {
    final currentState = ref.read(comprobantesSaleProvider);
    
    // Actualizar los controladores de texto
    _serieController.text = currentState.filtroSerie ?? '';
    _numeroController.text = currentState.filtroNumero ?? '';
    
    // Actualizar los selectores múltiples
    setState(() {
      _selectedDocumentTypes = currentState.filtroTipoComprobante ?? [];
      _selectedPaymentMethods = currentState.idMetodoPago ?? [];
      _selectedStatus = currentState.filtroEstado ?? 'Todos';
    });
  }



  void _applyFilters() {
    // Aplicar filtros al provider y hacer búsqueda
    ref.read(comprobantesSaleProvider.notifier).updateFilters(
      serie: _serieController.text.trim(),
      numero: _numeroController.text.trim(),
      tiposComprobante: _selectedDocumentTypes.isNotEmpty ? _selectedDocumentTypes : null,
      metodosPago: _selectedPaymentMethods.isNotEmpty 
          ? _selectedPaymentMethods 
          : null,
      estado: _selectedStatus, // "Todos", "Activos", o "Anulados"
    );
    widget.onApplyFilters?.call();
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
                  onChanged: (_) {}, // Solo cambio local, no actualizar provider
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFieldSection(
                  label: 'Número',
                  hint: 'Ej. 000123',
                  inputType: TextInputType.number,
                  controller: _numeroController,
                  onChanged: (_) {}, // Solo cambio local, no actualizar provider
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
              // Solo cambio local, no actualizar provider hasta Aplicar
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
              // Solo cambio local, no actualizar provider hasta Aplicar
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
                  // No llamar _updateLocalFilters() aquí para evitar actualizaciones prematuras
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
              style: GoogleFonts.roboto(
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
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
              backgroundColor: ColorSchema.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              ),
              child: Text(
              'Aplicar',
              style: GoogleFonts.roboto(
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