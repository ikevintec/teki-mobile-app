import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/seller.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/selector/multi_selector.dart';
import 'package:teki_app/src/presentation/widgets/segment/custom_segment_selector.dart';
import 'package:teki_app/src/providers/accounts_receivable/seller_provider.dart';
import 'package:teki_app/src/providers/comprobantes/comprobantes_notifier.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/constants.dart';

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
  final TextEditingController _vendedorController = TextEditingController();

  List<String> _selectedPaymentMethods = [];
  List<String> _selectedDocumentTypes = [];
  String _selectedStatus = 'Todos';
  List<Map<String, String>> _paymentMethods = [];
  int? _selectedVendedorId;

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
    _vendedorController.dispose();
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

      // Vendedor: solo aplica cuando el usuario puede ver todos los vendedores.
      // 0 = todos. Recuperamos el nombre desde la lista ya cargada.
      if (ref.read(puedeVerTodosVendedoresProvider)) {
        _selectedVendedorId =
            currentState.idVendedor > 0 ? currentState.idVendedor : null;
        if (_selectedVendedorId != null) {
          final seller = ref
              .read(sellersProvider)
              .where((s) => s.id == _selectedVendedorId)
              .firstOrNull;
          _vendedorController.text = seller?.nombreCompleto ?? '';
        }
      }
    });
  }

  Future<void> _showSellerSheet() async {
    final sellers = ref.read(sellersProvider);
    final selected = await showModalBottomSheet<Seller?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SellerPickerSheet(
        sellers: sellers,
        selectedId: _selectedVendedorId,
      ),
    );

    // selected == null significa que se cerró sin elegir -> no cambiar nada.
    // Un Seller con id == null representa la opción "Todos los vendedores".
    if (selected == null) return;
    setState(() {
      _selectedVendedorId = selected.id;
      _vendedorController.text = selected.id == null
          ? ''
          : (selected.nombreCompleto ?? '');
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
      idVendedor: _selectedVendedorId ?? 0, // 0 = todos los vendedores
    );
    widget.onApplyFilters?.call();
  }

  Widget _buildVendedorField() {
    // Sin permiso para ver todos los vendedores: campo bloqueado mostrando el
    // vendedor de la sesión (no se puede cambiar).
    if (!ref.watch(puedeVerTodosVendedoresProvider)) {
      return _buildVendedorFieldDisabled();
    }

    final hasSelection = _selectedVendedorId != null &&
        _vendedorController.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vendedor',
          style: GoogleFonts.raleway(
            color: const Color(0xFF444444),
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showSellerSheet,
          borderRadius: BorderRadius.circular(20),
          child: InputDecorator(
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFE2E4E7)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFE2E4E7)),
              ),
              suffixIcon: hasSelection
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        setState(() {
                          _selectedVendedorId = null;
                          _vendedorController.clear();
                        });
                      },
                    )
                  : const Icon(Icons.keyboard_arrow_down),
            ),
            child: Text(
              hasSelection
                  ? _vendedorController.text
                  : 'Todos los vendedores',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: hasSelection ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVendedorFieldDisabled() {
    final user = ref.read(sesionProvider).login.user;
    final nombre = user?.nombreCompleto ?? user?.name ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vendedor',
          style: GoogleFonts.raleway(
            color: const Color(0xFF444444),
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: InputDecoration(
            enabled: false,
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFF2F3F5),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: const Icon(Icons.lock_outline,
                size: 18, color: Colors.grey),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFFE2E4E7)),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFFE2E4E7)),
            ),
          ),
          child: Text(
            nombre.isNotEmpty ? nombre : 'Vendedor de la sesión',
            style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[700]),
          ),
        ),
      ],
    );
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
          // Vendedor: input de solo lectura que abre un sheet de selección
          _buildVendedorField(),
          const SizedBox(height: 16),

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
            hint: 'Tipos de documentos',
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

/// Sheet de selección de vendedor. Devuelve el [Seller] elegido al cerrarse,
/// un [Seller] con id == null para la opción "Todos los vendedores", o null si
/// se cerró sin seleccionar.
class _SellerPickerSheet extends StatefulWidget {
  final List<Seller> sellers;
  final int? selectedId;

  const _SellerPickerSheet({
    required this.sellers,
    required this.selectedId,
  });

  @override
  State<_SellerPickerSheet> createState() => _SellerPickerSheetState();
}

class _SellerPickerSheetState extends State<_SellerPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.sellers
        : widget.sellers
            .where((s) =>
                (s.nombreCompleto ?? '').toLowerCase().contains(query))
            .toList();
    final maxHeight = MediaQuery.of(context).size.height * 0.8;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ColorSchema.primaryColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_outline,
                      color: ColorSchema.primaryColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Seleccionar vendedor',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: ColorSchema.primaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: ColorSchema.primaryColor),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  hintText: 'Buscar vendedor',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xFFE2E4E7)),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xFFE2E4E7)),
                  ),
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  ListTile(
                    leading: const Icon(Icons.groups_outlined),
                    title: Text(
                      'Todos los vendedores',
                      style: GoogleFonts.roboto(fontSize: 14),
                    ),
                    trailing: widget.selectedId == null
                        ? Icon(Icons.check, color: ColorSchema.primaryColor)
                        : null,
                    onTap: () => Navigator.pop(context, Seller()),
                  ),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Sin resultados',
                        style: GoogleFonts.roboto(
                            fontSize: 13, color: Colors.grey),
                      ),
                    )
                  else
                    ...filtered.map(
                      (seller) => ListTile(
                        dense: true,
                        title: Text(
                          seller.nombreCompleto ?? '',
                          style: GoogleFonts.roboto(fontSize: 14),
                        ),
                        trailing: widget.selectedId == seller.id
                            ? Icon(Icons.check,
                                color: ColorSchema.primaryColor)
                            : null,
                        onTap: () => Navigator.pop(context, seller),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}