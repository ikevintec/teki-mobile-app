import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/seller.dart';
import 'package:teki_app/src/presentation/widgets/selector/multi_selector.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/providers/accounts_receivable/accounts_receivable_notifier.dart';
import 'package:teki_app/src/providers/accounts_receivable/seller_provider.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/contstants.dart';

const List<Map<String, String>> _tipoComprobanteOptions = [
  {'label': 'Factura', 'value': '01'},
  {'label': 'Boleta de Venta', 'value': '03'},
  {'label': 'Nota de Crédito', 'value': '07'},
  {'label': 'Nota de Débito', 'value': '08'},
];

const List<Map<String, String>> _estadoCreditoOptions = [
  {'label': 'Pendiente', 'value': 'PENDIENTE'},
  {'label': 'Anulado', 'value': 'ANULADO'},
  {'label': 'Vencido', 'value': 'VENCIDO'},
  {'label': 'Pagado', 'value': 'PAGADO'},
  {'label': 'Refinanciado', 'value': 'REFINANCIADO'},
];

class OtherFiltersModal extends ConsumerStatefulWidget {
  final String tipoCuenta;

  const OtherFiltersModal({super.key, required this.tipoCuenta});

  @override
  ConsumerState<OtherFiltersModal> createState() => _OtherFiltersModalState();
}

class _OtherFiltersModalState extends ConsumerState<OtherFiltersModal> {
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _serieController = TextEditingController();
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _comprobanteController = TextEditingController();
  final TextEditingController _diasCreditoController = TextEditingController();
  final TextEditingController _vendedorController = TextEditingController();
  final FocusNode _vendedorFocusNode = FocusNode();
  bool _vendedorFocused = false;

  List<String> _tipoComprobante = [];
  List<String> _estadoCredito = [];
  int? _idPuntoVenta;
  int? _idVendedor;

  @override
  void initState() {
    super.initState();
    _vendedorFocusNode.addListener(() {
      setState(() => _vendedorFocused = _vendedorFocusNode.hasFocus);
    });
    final state = ref.read(accountsReceivableProvider(widget.tipoCuenta));
    _numeroController.text = state.numero ?? '';
    _serieController.text = state.serie ?? '';
    _clienteController.text = state.cliente ?? '';
    _comprobanteController.text = state.comprobante ?? '';
    _diasCreditoController.text = state.diasCredito ?? '';
    _tipoComprobante = state.tipoComprobante ?? [];
    _estadoCredito = state.estadoCredito ?? [];
    _idPuntoVenta = state.idPuntoVenta;
    _idVendedor = state.idVendedor;

    if (_idVendedor != null) {
      final sellers = ref.read(sellersProvider);
      final seller = sellers.where((s) => s.id == _idVendedor).firstOrNull;
      _vendedorController.text = seller?.nombreCompleto ?? '';
    }
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _serieController.dispose();
    _clienteController.dispose();
    _comprobanteController.dispose();
    _diasCreditoController.dispose();
    _vendedorController.dispose();
    _vendedorFocusNode.dispose();
    super.dispose();
  }

  void _apply() {
    ref.read(accountsReceivableProvider(widget.tipoCuenta).notifier).applyOtherFilters(
          tipoComprobante: _tipoComprobante.isNotEmpty ? _tipoComprobante : null,
          numero: _numeroController.text.trim().isNotEmpty
              ? _numeroController.text.trim()
              : null,
          serie: _serieController.text.trim().isNotEmpty
              ? _serieController.text.trim()
              : null,
          cliente: _clienteController.text.trim().isNotEmpty
              ? _clienteController.text.trim()
              : null,
          comprobante: _comprobanteController.text.trim().isNotEmpty
              ? _comprobanteController.text.trim()
              : null,
          diasCredito: _diasCreditoController.text.trim().isNotEmpty
              ? _diasCreditoController.text.trim()
              : null,
          estadoCredito: _estadoCredito.isNotEmpty ? _estadoCredito : null,
          idVendedor: _idVendedor,
          idPuntoVenta: _idPuntoVenta,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final offices = ref.watch(sesionProvider).offices ?? <Office>[];
    final sellers = ref.watch(sellersProvider);
    final maxHeight = MediaQuery.of(context).size.height * 0.92;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ColorSchema.primaryColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tune, color: ColorSchema.primaryColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Otros filtros',
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
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFields(offices, sellers),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _buildActionButtons(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFields(List<Office> offices, List<Seller> sellers) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVendedorField(sellers),
          const SizedBox(height: 16),
          if (widget.tipoCuenta == 'CC')
            Row(
              children: [
                Expanded(
                  child: TextFieldSection(
                    label: 'Serie',
                    hint: 'Ej. F001',
                    inputType: TextInputType.text,
                    controller: _serieController,
                    showDoneButton: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFieldSection(
                    label: 'Número',
                    hint: 'Ej. 000123',
                    inputType: TextInputType.number,
                    controller: _numeroController,
                    showDoneButton: true,
                  ),
                ),
              ],
            )
          else
            TextFieldSection(
              label: 'Comprobante',
              hint: 'Buscar comprobante',
              inputType: TextInputType.text,
              controller: _comprobanteController,
              showDoneButton: true,
            ),
          const SizedBox(height: 16),
          TextFieldSection(
            label: widget.tipoCuenta == 'CC' ? 'Cliente' : 'Proveedor',
            hint: widget.tipoCuenta == 'CC' ? 'Buscar cliente' : 'Buscar proveedor',
            inputType: TextInputType.text,
            controller: _clienteController,
            showDoneButton: true,
          ),
          const SizedBox(height: 16),
          TextFieldSection(
            label: 'Días de crédito',
            hint: 'Ej. 30',
            inputType: TextInputType.number,
            controller: _diasCreditoController,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            showDoneButton: true,
          ),
          const SizedBox(height: 16),
          MultiSelector(
            label: 'Tipo de comprobante',
            hint: 'Selecciona tipos de documentos',
            options: _tipoComprobanteOptions,
            selectedValues: _tipoComprobante,
            onChanged: (values) => setState(() => _tipoComprobante = values),
          ),
          const SizedBox(height: 16),
          MultiSelector(
            label: 'Estado',
            hint: 'Selecciona estados',
            options: _estadoCreditoOptions,
            selectedValues: _estadoCredito,
            onChanged: (values) => setState(() => _estadoCredito = values),
          ),
          const SizedBox(height: 16),
          _buildPuntoVentaSelector(offices),
        ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Volver',
              style: GoogleFonts.roboto(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _apply,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorSchema.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Aplicar',
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPuntoVentaSelector(List<Office> offices) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E4E7)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<int?>(
              value: _idPuntoVenta,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                border: InputBorder.none,
              ),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
                ...offices.map(
                  (office) => DropdownMenuItem<int?>(
                    value: office.id,
                    child: Text(office.nombre ?? office.nombreCorto ?? '--'),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _idPuntoVenta = value),
            ),
          ),
        ),
        Positioned(
          left: 12,
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            color: Colors.white,
            child: Text(
              'Punto de venta',
              style: GoogleFonts.raleway(
                color: const Color(0xFF444444),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVendedorField(List<Seller> sellers) {
    final query = _vendedorController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? sellers
        : sellers
            .where((s) => (s.nombreCompleto ?? '').toLowerCase().contains(query))
            .toList();
    final showSuggestions = _vendedorFocused && _idVendedor == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: TextField(
                controller: _vendedorController,
                focusNode: _vendedorFocusNode,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  hintText: 'Buscar vendedor',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xFFE2E4E7)),
                  ),
                  suffixIcon: _vendedorController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setState(() {
                              _vendedorController.clear();
                              _idVendedor = null;
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    if (_idVendedor != null) _idVendedor = null;
                  });
                },
              ),
            ),
            Positioned(
              left: 12,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                color: Colors.white,
                child: Text(
                  'Vendedor',
                  style: GoogleFonts.raleway(
                    color: const Color(0xFF444444),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E4E7)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Sin resultados',
                      style: GoogleFonts.roboto(fontSize: 13, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final seller = filtered[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          seller.nombreCompleto ?? '',
                          style: GoogleFonts.roboto(fontSize: 14),
                        ),
                        onTap: () {
                          setState(() {
                            _vendedorController.text = seller.nombreCompleto ?? '';
                            _idVendedor = seller.id;
                          });
                          _vendedorFocusNode.unfocus();
                        },
                      );
                    },
                  ),
          ),
      ],
    );
  }
}
