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
  int? id;

  final GlobalKey _fieldKey = GlobalKey();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

// 1. Mapeo de códigos a texto
  final Map<String, String> tipoDocumentoMap = {
    '0': 'DOC NO DOM SIN RUC',
    '1': 'DNI',
    '4': 'CARNET DE EXT.',
    '6': 'RUC',
    '7': 'PASAPORTE',
    'A': 'CED DIPLOMATICA IDENTIDAD',
  };

  String? _selectedTipoDocumentoValue = '1';

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
  void initState() {
    super.initState();
    final clientProvider = ref.read(customerSaleProvider);
    if ((clientProvider.customer.razonSocial ?? '').isNotEmpty) {
      _nombreController.text = clientProvider.customer.razonSocial ?? '';
      _direccionController.text = clientProvider.customer.direccion ?? '';
      _documentoController.text = clientProvider.customer.numeroDocumento ?? '';
      _emailController.text = clientProvider.customer.email ?? '';
      _telefonoController.text = clientProvider.customer.telefono ?? '';
    }
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
    final clienteNotifier = ref.read(customerSaleProvider.notifier);
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
                        //From
                        child: Form(
                          key: _formKey,
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
                              Autocomplete<Customer>(
                                optionsBuilder:
                                    (TextEditingValue textEditingValue) async {
                                  if (textEditingValue.text.trim().isEmpty) {
                                    clienteNotifier.clearCustomers();
                                    return const Iterable<Customer>.empty();
                                  }

                                  return await onSearchChanged(
                                      textEditingValue.text);
                                },
                                displayStringForOption: (Customer option) =>
                                    option.razonSocial ?? 'Sin nombre',
                                fieldViewBuilder: (context, controller,
                                    focusNode, onEditingComplete) {
                                  if (controller.text.isEmpty &&
                                      _nombreController.text.isNotEmpty) {
                                    controller.text = _nombreController.text;
                                  }

                                  _nombreController.value = controller.value;

                                  return Container(
                                    key: _fieldKey,
                                    child: TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      decoration: const InputDecoration(
                                        labelText: 'Nombre',
                                        hintText: 'Ingrese el nombre',
                                        filled: true,
                                        fillColor:
                                            Color.fromARGB(255, 255, 255, 255),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(12)),
                                          borderSide: BorderSide(
                                              color: Color.fromARGB(
                                                  255, 233, 233, 233)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(30)),
                                          borderSide: BorderSide(
                                              color: Color.fromARGB(
                                                  255, 194, 194, 194)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(30)),
                                          borderSide: BorderSide(
                                            color: ColorSchema.primaryColor,
                                            width: 1,
                                          ),
                                        ),
                                        prefixIcon: Icon(Icons.person),
                                      ),
                                      style: const TextStyle(fontSize: 14),
                                      onEditingComplete: () {
                                        FocusScope.of(context).unfocus();
                                      },
                                    ),
                                  );
                                },
                                optionsViewBuilder:
                                    (context, onSelected, options) {
                                  final renderBox = _fieldKey.currentContext
                                      ?.findRenderObject() as RenderBox?;
                                  final fieldWidth =
                                      renderBox?.size.width ?? 400;

                                  return Align(
                                    alignment: Alignment.topLeft,
                                    child: ConstrainedBox(
                                      constraints:
                                          BoxConstraints(maxWidth: fieldWidth),
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
                                          itemBuilder: (context, index) {
                                            final customer =
                                                options.elementAt(index);
                                            return ListTile(
                                              leading: const Icon(Icons.person),
                                              title: Text(
                                                customer.razonSocial ??
                                                    'Sin nombre',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              subtitle: Text(
                                                customer.numeroDocumento
                                                        ?.toString() ??
                                                    '',
                                                style: const TextStyle(
                                                    color: Colors.grey),
                                              ),
                                              onTap: () => onSelected(customer),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                onSelected: (Customer selection) {
                                  FocusScope.of(context).unfocus();
                                  clienteNotifier.selectCustomer(selection);
                                  _documentoController.text =
                                      selection.numeroDocumento?.toString() ??
                                          '';
                                  _direccionController.text =
                                      selection.direccionCompleta ?? '';
                                  _emailController.text = selection.email ?? '';
                                  _telefonoController.text =
                                      selection.telefono ?? '';
                                  id = selection.id;

                                  final tipoDocCodigo =
                                      selection.tipoDocumento?.toString();
                                  if (tipoDocCodigo != null &&
                                      tipoDocumentoMap
                                          .containsKey(tipoDocCodigo)) {
                                    setState(() {
                                      _selectedTipoDocumentoValue =
                                          tipoDocCodigo;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 20),
                              DropdownFormFieldSection(
                                label: "Tipo documento",
                                hint: "Selecciona un tipo documento",
                                items: tipoDocumentoMap.values.toList(),
                                selectionItem: tipoDocumentoMap[
                                    _selectedTipoDocumentoValue ?? ''],
                                onChanged: (value) {
                                  final selectedCode = tipoDocumentoMap.entries
                                      .firstWhere(
                                          (entry) => entry.value == value)
                                      .key;
                                  setState(() {
                                    _selectedTipoDocumentoValue = selectedCode;
                                  });
                                },
                              ),
                              const SizedBox(height: 20),
                              TextFieldSection(
                                label: "Número Documento",
                                controller: _documentoController,
                                hint: "Ingrese el número de documento",
                                inputType: TextInputType.number,
                                //icon: const Icon(Icons.edit_document),
                                onChanged:
                                    (_) {}, // Puedes enlazar con tu lógica si es necesario
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Este campo es obligatorio';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              TextFieldSection(
                                label: "Dirección fiscal",
                                controller: _direccionController,
                                hint: "Ingrese su dirección fiscal",
                                inputType: TextInputType.text,
                                //icon: const Icon(Icons.location_on),
                                //maxLength: 100,
                                onChanged:
                                    (_) {}, // Puedes manejar cambios si es necesario
                                validator: (value) {
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              TextFieldSection(
                                label: "Email",
                                controller: _emailController,
                                hint: "Ingrese su email",
                                inputType: TextInputType.emailAddress,
                                //icon: const Icon(Icons.email),
                                //maxLength: 100,
                                onChanged:
                                    (_) {}, // Puedes manejar cambios si lo necesitas
                                validator: (value) {
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              TextFieldSection(
                                label: "Teléfono",
                                controller: _telefonoController,
                                hint: "Ingrese su teléfono",
                                inputType: TextInputType.phone,
                                //icon: const Icon(Icons.phone),
                                //maxLength: 9,
                                onChanged:
                                    (_) {}, // Puedes enlazar lógica aquí si lo necesitas
                                validator: (value) {
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                clienteNotifier.setCustomer(
                                    id: id,
                                    nombre: _nombreController.text,
                                    direccion: _direccionController.text,
                                    documento: _documentoController.text,
                                    email: _emailController.text,
                                    telefono: _telefonoController.text,
                                    tipoDocumento:
                                        _selectedTipoDocumentoValue ?? '');
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const SaleInfoScreen()),
                                );
                              }
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
