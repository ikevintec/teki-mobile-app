import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/cutomer.dart';
import 'package:teki_app/src/presentation/screens/sale/sale_info/sale_info_screen.dart';
import 'package:teki_app/src/presentation/screens/sale/widgets/summary_bar.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_provider.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/formats.dart';

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
  TextEditingController? _autocompleteController;
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
    Customer customer = clientProvider.customer;

    // Si no hay cliente cargado, usar el cliente por defecto de la sesión
    if ((customer.razonSocial ?? '').isEmpty) {
      final defaultCustomer =
          ref.read(sesionProvider).config?.clientePorDefectoData;
      if (defaultCustomer != null) {
        customer = defaultCustomer;
        // Diferir la modificación del provider para evitar modificarlo durante el build
        Future.microtask(() {
          if (mounted) {
            ref.read(customerSaleProvider.notifier).setCustomerEntity(customer);
          }
        });
      }
    }

    if ((customer.razonSocial ?? '').isNotEmpty) {
      _nombreController.text = customer.razonSocial ?? '';
      _direccionController.text = customer.direccion ?? '';
      _documentoController.text = customer.numeroDocumento ?? '';
      _emailController.text = customer.email ?? '';
      _telefonoController.text = customer.telefono ?? '';
      final tipoDocCodigo = customer.tipoDocumento?.toString();
      if (tipoDocCodigo != null && tipoDocumentoMap.containsKey(tipoDocCodigo)) {
        _selectedTipoDocumentoValue = tipoDocCodigo;
      }
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

  void updateCustomerDisplay(Customer customer) {
    ref.read(customerSaleProvider.notifier).selectCustomer(customer);
    
    final customerName = customer.razonSocial ?? '';
    
    _nombreController.text = customerName;
    if (_autocompleteController != null) {
      _autocompleteController!.text = customerName;
    }
    
    _documentoController.text = customer.numeroDocumento ?? '';
    _direccionController.text = customer.direccionCompleta ?? '';
    _emailController.text = customer.email ?? '';
    _telefonoController.text = customer.telefono ?? '';

    final tipoDocCodigo = customer.tipoDocumento?.toString();
    if (tipoDocCodigo != null &&
        tipoDocumentoMap.containsKey(tipoDocCodigo)) {
      setState(() {
        _selectedTipoDocumentoValue = tipoDocCodigo;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final clienteNotifier = ref.read(customerSaleProvider.notifier);
    final ticketP = ref.watch(ticketProvider);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(ticketP.ticket.pedidoRestaurante != null ? 72 : 60),
        child: CustomAppBar(
          navigateName: "Cliente",
          subtitle: ticketP.ticket.pedidoRestaurante != null
              ? 'Pedido #${formatOrderNumber(ticketP.ticket.pedidoRestaurante!.id)}'
              : null,
        ),
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
                                  _autocompleteController = controller;
                                  
                                  if (controller.text.isEmpty && _nombreController.text.isNotEmpty) {
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
                                  updateCustomerDisplay(selection);
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
                                onChanged: (value) async {
                                  value = value.trim();
                                  if (value.isEmpty) {
                                    return;
                                  }
                                    // Validar y buscar cliente según el tipo de documento y su longitud
                                    final tipoDoc = _selectedTipoDocumentoValue;
                                    if (tipoDoc == '6' && value.length == 11) {
                                    // RUC
                                    final customers = await ref.read(customerSaleProvider.notifier).getCustomerss(value);
                                    if (customers.isNotEmpty) {
                                      updateCustomerDisplay(customers.first);
                                    }
                                    } else if (tipoDoc == '1' && value.length == 8) {
                                    // DNI
                                    final customers = await ref.read(customerSaleProvider.notifier).getCustomerss(value);
                                    if (customers.isNotEmpty) {
                                      updateCustomerDisplay(customers.first);
                                    }
                                    } else if (tipoDoc == '4' && value.length == 9) {
                                    // CARNET DE EXT.
                                    final customers = await ref.read(customerSaleProvider.notifier).getCustomerss(value);
                                    if (customers.isNotEmpty) {
                                      updateCustomerDisplay(customers.first);
                                    }
                                    } else if (tipoDoc == '7' && value.length >= 8 && value.length <= 12) {
                                    // PASAPORTE
                                    final customers = await ref.read(customerSaleProvider.notifier).getCustomerss(value);
                                    if (customers.isNotEmpty) {
                                      updateCustomerDisplay(customers.first);
                                    }
                                    }
                                }, // Puedes enlazar con tu lógica si es necesario
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Este campo es obligatorio';
                                  }
                                  
                                  // Validaciones específicas por tipo de documento
                                  final tipoDoc = _selectedTipoDocumentoValue;
                                  final documento = value.trim();
                                  
                                  switch (tipoDoc) {
                                    case '1': // DNI
                                      if (!RegExp(r'^\d{8}$').hasMatch(documento)) {
                                        return 'DNI debe tener exactamente 8 dígitos';
                                      }
                                      break;
                                    case '6': // RUC
                                      if (!RegExp(r'^\d{11}$').hasMatch(documento)) {
                                        return 'RUC debe tener exactamente 11 dígitos';
                                      }
                                      break;
                                    case '4': // CARNET DE EXTRANJERÍA
                                      if (!RegExp(r'^\d{9}$').hasMatch(documento)) {
                                        return 'Carnet de extranjería debe tener 9 dígitos';
                                      }
                                      break;
                                    case '7': // PASAPORTE
                                      if (!RegExp(r'^[A-Za-z0-9]{8,12}$').hasMatch(documento)) {
                                        return 'Pasaporte debe tener entre 8 y 12 caracteres alfanuméricos';
                                      }
                                      break;
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
                    SummaryBarSales(),
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
                              children: [
                                Text(ticketP.isEdit ? 'Continuar Edición' : 'Continuar'),
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
