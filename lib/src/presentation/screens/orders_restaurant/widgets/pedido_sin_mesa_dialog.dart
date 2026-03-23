import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/cutomer.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_provider.dart';
import 'package:teki_app/src/utils/contstants.dart';

// ---------------------------------------------------------------------------
// Result data class
// ---------------------------------------------------------------------------

class PedidoSinMesaFormData {
  final String tipo;
  final bool generarComprobante;
  final String nombreCliente;
  final String tipoDocumentoReceptor;
  final String numeroDocumentoReceptor;
  final String denominacionReceptor;
  final String direccionReceptor;
  final String emailReceptor;
  final String telefonoReceptor;
  final String? direccionCompleta;
  final double? montoDelivery;

  const PedidoSinMesaFormData({
    required this.tipo,
    required this.generarComprobante,
    required this.nombreCliente,
    required this.tipoDocumentoReceptor,
    required this.numeroDocumentoReceptor,
    required this.denominacionReceptor,
    required this.direccionReceptor,
    required this.emailReceptor,
    required this.telefonoReceptor,
    this.direccionCompleta,
    this.montoDelivery,
  });
}

// ---------------------------------------------------------------------------
// Show helper
// ---------------------------------------------------------------------------

Future<PedidoSinMesaFormData?> showPedidoSinMesaDialog(BuildContext context) {
  return showDialog<PedidoSinMesaFormData>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PedidoSinMesaDialog(),
  );
}

// ---------------------------------------------------------------------------
// Dialog widget
// ---------------------------------------------------------------------------

class PedidoSinMesaDialog extends ConsumerStatefulWidget {
  const PedidoSinMesaDialog({super.key});

  @override
  ConsumerState<PedidoSinMesaDialog> createState() =>
      _PedidoSinMesaDialogState();
}

class _PedidoSinMesaDialogState extends ConsumerState<PedidoSinMesaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _autocompleteFieldKey = GlobalKey();
  Timer? _debounce;
  TextEditingController? _autocompleteController;

  // Tipo de pedido
  String _tipo = 'PEDIDO_LOCAL_INTERNO';
  bool _generarComprobante = true;

  // Controllers
  final _nombreController = TextEditingController();
  final _documentoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionCompletaController = TextEditingController();
  final _montoDeliveryController = TextEditingController();

  String? _selectedTipoDocumento = '1';

  static const Map<String, String> _tipoDocumentoMap = {
    '0': 'DOC NO DOM SIN RUC',
    '1': 'DNI',
    '4': 'CARNET DE EXT.',
    '6': 'RUC',
    '7': 'PASAPORTE',
    'A': 'CED DIPLOMATICA IDENTIDAD',
  };

  static const List<Map<String, String>> _orderTypes = [
    {'value': 'PEDIDO_LOCAL_INTERNO', 'label': 'Interno'},
    {'value': 'PEDIDO_LOCAL', 'label': 'Para llevar'},
    {'value': 'PEDIDO_FORANEO', 'label': 'Delivery'},
  ];

  bool get _isDelivery => _tipo == 'PEDIDO_FORANEO';

  @override
  void initState() {
    super.initState();
    _loadDefaultCustomer();
  }

  void _loadDefaultCustomer() {
    final defaultCustomer =
        ref.read(sesionProvider).config?.clientePorDefectoData;
    if (defaultCustomer != null) {
      _fillCustomerData(defaultCustomer);
    }
  }

  void _fillCustomerData(Customer customer) {
    setState(() {
      _nombreController.text = customer.razonSocial ?? '';
      _documentoController.text = customer.numeroDocumento ?? '';
      _direccionController.text =
          customer.direccion ?? customer.direccionCompleta ?? '';
      _emailController.text = customer.email ?? '';
      _telefonoController.text = customer.telefono ?? '';
      final tipoDoc = customer.tipoDocumento?.toString();
      if (tipoDoc != null && _tipoDocumentoMap.containsKey(tipoDoc)) {
        _selectedTipoDocumento = tipoDoc;
      }
      if (_autocompleteController != null) {
        _autocompleteController!.text = customer.razonSocial ?? '';
      }
    });
  }

  Future<List<Customer>> _searchCustomers(String query) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    final completer = Completer<List<Customer>>();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.trim().isNotEmpty) {
        final customers =
            await ref.read(customerSaleProvider.notifier).getCustomerss(query);
        completer.complete(customers);
      } else {
        completer.complete([]);
      }
    });
    return completer.future;
  }

  void _tryAutoSearchByDocument(String documento) async {
    final tipoDoc = _selectedTipoDocumento;
    bool shouldSearch = false;
    if (tipoDoc == '6' && documento.length == 11) {
      shouldSearch = true;
    } else if (tipoDoc == '1' && documento.length == 8) {
      shouldSearch = true;
    } else if (tipoDoc == '4' && documento.length == 9) {
      shouldSearch = true;
    } else if (tipoDoc == '7' && documento.length >= 8 && documento.length <= 12) {
      shouldSearch = true;
    }

    if (shouldSearch) {
      final customers =
          await ref.read(customerSaleProvider.notifier).getCustomerss(documento);
      if (customers.isNotEmpty && mounted) {
        _fillCustomerData(customers.first);
      }
    }
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    final nombre = _nombreController.text.trim();
    Navigator.pop(
      context,
      PedidoSinMesaFormData(
        tipo: _tipo,
        generarComprobante: _generarComprobante,
        nombreCliente: nombre,
        tipoDocumentoReceptor: _selectedTipoDocumento ?? '1',
        numeroDocumentoReceptor: _documentoController.text.trim(),
        denominacionReceptor: nombre,
        direccionReceptor: _direccionController.text.trim(),
        emailReceptor: _emailController.text.trim(),
        telefonoReceptor: _telefonoController.text.trim(),
        direccionCompleta: _isDelivery
            ? _direccionCompletaController.text.trim()
            : null,
        montoDelivery: _isDelivery &&
                _montoDeliveryController.text.trim().isNotEmpty
            ? double.tryParse(_montoDeliveryController.text.trim())
            : null,
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nombreController.dispose();
    _documentoController.dispose();
    _direccionController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _direccionCompletaController.dispose();
    _montoDeliveryController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTipoCard(),
                    const SizedBox(height: 12),
                    _buildClienteCard(),
                    if (_isDelivery) ...[
                      const SizedBox(height: 12),
                      _buildDeliveryCard(),
                    ],
                  ],
                ),
              ),
            ),
          ),
          _buildActions(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: ColorSchema.primaryColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Configurar Pedido',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context, null),
            child: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tipo card
  // ---------------------------------------------------------------------------

  Widget _buildTipoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tipo de pedido',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 10),
          ..._orderTypes.map(
            (type) => _TypeOptionTile(
              label: type['label']!,
              value: type['value']!,
              selected: _tipo == type['value'],
              onTap: () => setState(() => _tipo = type['value']!),
            ),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Generar comprobante',
                  style: TextStyle(fontSize: 14)),
              Switch(
                value: _generarComprobante,
                activeColor: ColorSchema.primaryColor,
                onChanged: (v) => setState(() => _generarComprobante = v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Cliente card
  // ---------------------------------------------------------------------------

  Widget _buildClienteCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datos del cliente',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          // Autocomplete name field
          Autocomplete<Customer>(
            optionsBuilder: (textEditingValue) async {
              if (textEditingValue.text.trim().isEmpty) return const [];
              return await _searchCustomers(textEditingValue.text);
            },
            displayStringForOption: (c) => c.razonSocial ?? '',
            fieldViewBuilder:
                (context, controller, focusNode, onEditingComplete) {
              _autocompleteController = controller;
              if (controller.text.isEmpty &&
                  _nombreController.text.isNotEmpty) {
                controller.text = _nombreController.text;
              }
              _nombreController.value = controller.value;
              return Container(
                key: _autocompleteFieldKey,
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Nombre *',
                    hintText: 'Buscar cliente por nombre',
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                          const BorderSide(color: Color(0xFFE2E4E7)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                          color: ColorSchema.primaryColor),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              final renderBox = _autocompleteFieldKey.currentContext
                  ?.findRenderObject() as RenderBox?;
              final fieldWidth = renderBox?.size.width ?? 300.0;
              return Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: fieldWidth),
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(8),
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final customer = options.elementAt(i);
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.person, size: 18),
                          title: Text(
                            customer.razonSocial ?? 'Sin nombre',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            customer.numeroDocumento ?? '',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          onTap: () => onSelected(customer),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            onSelected: (customer) {
              FocusScope.of(context).unfocus();
              _fillCustomerData(customer);
            },
          ),
          const SizedBox(height: 12),
          DropdownFormFieldSection(
            label: 'Tipo documento *',
            hint: 'Selecciona',
            items: _tipoDocumentoMap.values.toList(),
            selectionItem: _tipoDocumentoMap[_selectedTipoDocumento ?? ''],
            onChanged: (value) {
              if (value == null) return;
              final code = _tipoDocumentoMap.entries
                  .firstWhere((e) => e.value == value)
                  .key;
              setState(() => _selectedTipoDocumento = code);
            },
          ),
          const SizedBox(height: 12),
          TextFieldSection(
            label: 'Número de documento *',
            hint: 'Ingrese el documento',
            inputType: TextInputType.text,
            controller: _documentoController,
            onChanged: (v) => _tryAutoSearchByDocument(v.trim()),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 12),
          TextFieldSection(
            label: 'Dirección *',
            hint: 'Dirección fiscal',
            inputType: TextInputType.text,
            controller: _direccionController,
            onChanged: (_) {},
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 12),
          TextFieldSection(
            label: 'Email',
            hint: 'Email (opcional)',
            inputType: TextInputType.emailAddress,
            controller: _emailController,
            onChanged: (_) {},
            validator: (_) => null,
          ),
          const SizedBox(height: 12),
          TextFieldSection(
            label: 'Teléfono',
            hint: 'Teléfono (opcional)',
            inputType: TextInputType.phone,
            controller: _telefonoController,
            onChanged: (_) {},
            validator: (_) => null,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Delivery card (only for PEDIDO_FORANEO)
  // ---------------------------------------------------------------------------

  Widget _buildDeliveryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.delivery_dining,
                  color: Colors.orange.shade700, size: 18),
              const SizedBox(width: 8),
              Text(
                'Datos de delivery',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.orange.shade800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFieldSection(
            label: 'Dirección de entrega *',
            hint: 'Dirección completa para el delivery',
            inputType: TextInputType.text,
            controller: _direccionCompletaController,
            onChanged: (_) {},
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Campo requerido para delivery'
                : null,
          ),
          const SizedBox(height: 12),
          TextFieldSection(
            label: 'Monto delivery',
            hint: '0.00 (opcional)',
            inputType: TextInputType.number,
            controller: _montoDeliveryController,
            prefix: 'S/ ',
            onChanged: (_) {},
            validator: (v) {
              if (v != null && v.trim().isNotEmpty &&
                  double.tryParse(v.trim()) == null) {
                return 'Ingrese un monto válido';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, null),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cancelar',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _confirm,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Crear Pedido',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorSchema.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Type option tile
// ---------------------------------------------------------------------------

class _TypeOptionTile extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _TypeOptionTile({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? ColorSchema.primaryColor.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? ColorSchema.primaryColor
                : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? ColorSchema.primaryColor
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: ColorSchema.primaryColor,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
                color: selected
                    ? ColorSchema.primaryColor
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
