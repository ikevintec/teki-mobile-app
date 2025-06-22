import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/cutomer.dart';
import 'package:teki_app/src/presentation/screens/sale/sale_info/sale_info_screen.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_provider.dart';
import 'package:teki_app/src/utils/contstants.dart';

class ClientSaleScreen extends ConsumerStatefulWidget {
  const ClientSaleScreen({super.key});

  @override
  ConsumerState<ClientSaleScreen> createState() => _ClientSaleScreenState();
}

class _ClientSaleScreenState extends ConsumerState<ClientSaleScreen> {
  Timer? _debounce;
  final _nombreController = TextEditingController();
  final _documentoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
// 1. Mapeo de códigos a texto
  final Map<String, String> tipoDocumentoMap = {
    '0': 'DOC NO DOM SIN RUC',
    '1': 'DNI',
    '4': 'CARNET DE EXT.',
    '6': 'RUC',
    '7': 'PASAPORTE',
    'A': 'CED DIPLOMATICA IDENTIDAD',
  };
  String? _selectedTipoDocumentoValue = '1'; // default: DNI

  Future<List<Customer>> onSearchChanged(String query) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final completer = Completer<List<Customer>>();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.trim().isNotEmpty) {
        final customers =
            await ref.read(customerSaleProvider.notifier).getCustomerss(query);
        completer.complete(customers);
      } else {
        ref.read(customerSaleProvider.notifier).clearCustomers();
        completer.complete([]);
      }
    });

    return completer.future;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nombreController.dispose();
    _documentoController.dispose();
    _direccionController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerSaleProvider);

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(navigateName: "Cliente"),
      ),
      body: Container(
        color: ColorSchema.primaryColor,
        child: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_pin_outlined,
                                  color: ColorSchema.primaryColor,
                                  size: 70,
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),

                            /// Autocomplete para nombre
                            Autocomplete<Customer>(
                              optionsBuilder:
                                  (TextEditingValue textEditingValue) async {
                                if (textEditingValue.text.trim().isEmpty) {
                                  ref
                                      .read(customerSaleProvider.notifier)
                                      .clearCustomers();
                                  _direccionController.text = "";
                                  _documentoController.text = "";
                                  _emailController.text = "";
                                  _telefonoController.text = "";
                                  _nombreController.text = "";
                                  _selectedTipoDocumentoValue = "1";
                                  return const Iterable<Customer>.empty();
                                }

                                return await onSearchChanged(
                                    textEditingValue.text);
                              },
                              displayStringForOption: (Customer option) =>
                                  option.razonSocial ?? 'Sin nombre',
                              fieldViewBuilder: (context, controller, focusNode,
                                  onEditingComplete) {
                                _nombreController.value = controller.value;
                                return TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    labelText: 'Nombre',
                                    hintText: 'Ingrese el nombre',
                                    filled: true,
                                    fillColor: Color(0xFFF5F5F5),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(12)),
                                      borderSide:
                                          BorderSide(color: Colors.grey),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(12)),
                                      borderSide:
                                          BorderSide(color: Colors.grey),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(12)),
                                      borderSide: BorderSide(
                                          color: ColorSchema.primaryColor,
                                          width: 2),
                                    ),
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                  style: const TextStyle(fontSize: 16),
                                  onEditingComplete: onEditingComplete,
                                );
                              },
                              optionsViewBuilder:
                                  (context, onSelected, options) => Material(
                                elevation: 4,
                                borderRadius: BorderRadius.circular(12),
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(8),
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final customer = options.elementAt(index);
                                    return ListTile(
                                      title: Text(
                                          customer.razonSocial ?? 'Sin nombre'),
                                      subtitle: Text(customer.numeroDocumento
                                              ?.toString() ??
                                          ''),
                                      onTap: () => onSelected(customer),
                                    );
                                  },
                                ),
                              ),
                              onSelected: (Customer selection) {
                                ref
                                    .read(customerSaleProvider.notifier)
                                    .selectCustomer(selection);

                                _documentoController.text =
                                    selection.numeroDocumento?.toString() ?? '';
                                _direccionController.text =
                                    selection.direccionCompleta ?? '';
                                _emailController.text = selection.email ?? '';
                                _telefonoController.text =
                                    selection.telefono ?? '';

                                // 👇 Asigna el tipo de documento según el código recibido
                                final tipoDocCodigo =
                                    selection.tipoDocumento?.toString();
                                if (tipoDocCodigo != null &&
                                    tipoDocumentoMap
                                        .containsKey(tipoDocCodigo)) {
                                  setState(() {
                                    _selectedTipoDocumentoValue = tipoDocCodigo;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 30),
                            DropdownFormFieldSection(
                              label: "Tipo documento",
                              hint: "Selecciona un tipo documento",
                              items: tipoDocumentoMap.values.toList(),
                              selectionItem: tipoDocumentoMap[
                                  _selectedTipoDocumentoValue]!,
                              onChanged: (value) {
                                // Convierte el valor seleccionado (texto) a su código
                                final selectedCode = tipoDocumentoMap.entries
                                    .firstWhere((entry) => entry.value == value)
                                    .key;

                                setState(() {
                                  _selectedTipoDocumentoValue = selectedCode;
                                });
                              },
                            ),

                            const SizedBox(height: 30),
                            TextFieldSection(
                              label: "Numero Documento",
                              hint: "Numero Documento",
                              inputType: TextInputType.number,
                              controller: _documentoController,
                              onChanged: (value) {},
                            ),
                            const SizedBox(height: 30),
                            TextFieldSection(
                              label: "Direccion fiscal",
                              hint: "Direccion fiscal",
                              inputType: TextInputType.text,
                              controller: _direccionController,
                              onChanged: (value) {},
                            ),
                            const SizedBox(height: 30),
                            TextFieldSection(
                              label: "Email",
                              hint: "Email",
                              inputType: TextInputType.emailAddress,
                              controller: _emailController,
                              onChanged: (value) {},
                            ),
                            const SizedBox(height: 30),
                            TextFieldSection(
                              label: "Telefono",
                              hint: "Telefono",
                              inputType: TextInputType.phone,
                              controller: _telefonoController,
                              onChanged: (value) {},
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SaleInfoScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorSchema.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text('Continuar'),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_ios),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
