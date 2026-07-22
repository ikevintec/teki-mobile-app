import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/data/models/teki_model/customer.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/button/custom_elevated_button.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/loader/screen_loader.dart';
import 'package:teki_app/src/providers/customer_form/customer_form_provider.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/constants.dart';

class AddCustomerSection extends ConsumerStatefulWidget {
  final int? customerId;
  
  const AddCustomerSection({super.key, this.customerId});

  @override
  ConsumerState<AddCustomerSection> createState() => _AddCustomerSectionState();
}

class _AddCustomerSectionState extends ConsumerState<AddCustomerSection> {
  final _formKey = GlobalKey<FormState>();
  final _razonSocialController = TextEditingController();
  final _numeroDocumentoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  
  final Map<String, String> tipoDocumentoMap = {
    '0': 'DOC NO DOM SIN RUC',
    '1': 'DNI',
    '4': 'CARNET DE EXT.',
    '6': 'RUC',
    '7': 'PASAPORTE',
    'A': 'CED DIPLOMATICA IDENTIDAD',
  };

  String _selectedTipoDocumento = '1';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async{
      await ref.read(customerFormProvider.notifier).setFormMode(customerId: widget.customerId);
    });
  }

  void _updateControllers(Customer customer) {
    _razonSocialController.text = customer.razonSocial ?? '';
    _numeroDocumentoController.text = customer.numeroDocumento ?? '';
    _direccionController.text = customer.direccion ?? '';
    _emailController.text = customer.email ?? '';
    _telefonoController.text = customer.telefono ?? '';
    
    if (customer.tipoDocumento != null && tipoDocumentoMap.containsKey(customer.tipoDocumento)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedTipoDocumento = customer.tipoDocumento!;
        });
      });
    }
  }

  void _clearControllers() {
    _razonSocialController.clear();
    _numeroDocumentoController.clear();
    _direccionController.clear();
    _emailController.clear();
    _telefonoController.clear();
    setState(() {
      _selectedTipoDocumento = '1';
    });
  }

  @override
  void dispose() {
    _razonSocialController.dispose();
    _numeroDocumentoController.dispose();
    _direccionController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  String? _validateDocumentNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    
    final documento = value.trim();
    
    switch (_selectedTipoDocumento) {
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
  }

  void _updateCustomerData() {
    ref.read(customerFormProvider.notifier).setCustomerData(
      razonSocial: _razonSocialController.text,
      numeroDocumento: _numeroDocumentoController.text,
      tipoDocumento: _selectedTipoDocumento,
      direccion: _direccionController.text,
      email: _emailController.text,
      telefono: _telefonoController.text,
    );
  }

  void _handleSave() async {
    if (_formKey.currentState!.validate()) {
      _updateCustomerData();
      final customerFormNotifier = ref.read(customerFormProvider.notifier);
      await customerFormNotifier.proccessCustomerForm();
      
      final customerFormState = ref.read(customerFormProvider);
      if (!customerFormState.isLoading && customerFormState.error == null) {
        Get.until((route) => route.settings.name == AppRoutes.customer);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerFormState = ref.watch(customerFormProvider);
    final customer = customerFormState.customer;
    final isEditing = customerFormState.isEditing;
    final isLoading = customerFormState.isLoading;
    
    // Update controllers when customer data is loaded or clear for create mode
    if (customer != null && isEditing) {
      _updateControllers(customer);
    } else if (!isEditing && !isLoading) {
      // Clear controllers when in create mode
      _clearControllers();
    }

    if (isLoading) {
      return ScreenLoader(
        message: isEditing ? "Cargando cliente..." : "Preparando formulario...",
      );
    }
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: CustomAppBar(
          navigateName: isEditing ? "Editar Cliente" : "Crear Cliente",
        ),
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_pin_outlined,
                    color: ColorSchema.primaryColor,
                    size: 80,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFieldSection(
                label: "Razón Social / Nombre",
                hint: "Ingrese la razón social o nombre",
                inputType: TextInputType.text,
                controller: _razonSocialController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Este campo es obligatorio';
                  }
                  return null;
                },
                onChanged: (value) => _updateCustomerData(),
              ),
              const SizedBox(height: 20),
              DropdownFormFieldSection(
                label: "Tipo de Documento",
                hint: "Selecciona un tipo de documento",
                items: tipoDocumentoMap.values.toList(),
                selectionItem: tipoDocumentoMap[_selectedTipoDocumento],
                onChanged: (value) {
                  final selectedCode = tipoDocumentoMap.entries
                      .firstWhere((entry) => entry.value == value)
                      .key;
                  setState(() {
                    _selectedTipoDocumento = selectedCode;
                  });
                  _updateCustomerData();
                },
              ),
              const SizedBox(height: 20),
              TextFieldSection(
                label: "Número de Documento",
                hint: "Ingrese el número de documento",
                inputType: TextInputType.text,
                controller: _numeroDocumentoController,
                validator: _validateDocumentNumber,
                onChanged: (value) => _updateCustomerData(),
              ),
              const SizedBox(height: 20),
              TextFieldSection(
                label: "Teléfono",
                hint: "Ingrese el teléfono",
                inputType: TextInputType.phone,
                controller: _telefonoController,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!RegExp(r'^\d{9}$').hasMatch(value.trim())) {
                      return 'El teléfono debe tener 9 dígitos';
                    }
                  }
                  return null;
                },
                onChanged: (value) => _updateCustomerData(),
              ),
              const SizedBox(height: 20),
              TextFieldSection(
                label: "Email",
                hint: "Ingrese el email",
                inputType: TextInputType.emailAddress,
                controller: _emailController,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                      return 'Ingrese un email válido';
                    }
                  }
                  return null;
                },
                onChanged: (value) => _updateCustomerData(),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _direccionController,
                keyboardType: TextInputType.multiline,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Dirección",
                  hintText: "Ingrese la dirección",
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, // Grosor del label
                  ),
                  floatingLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, // Grosor cuando está flotando
                    color: Colors.black87, // Mantener color oscuro en focus
                  ),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 255, 255, 255),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Color.fromARGB(255, 233, 233, 233)),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    borderSide: BorderSide(color: Color.fromARGB(255, 194, 194, 194)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    borderSide: BorderSide(color: ColorSchema.primaryColor, width: 1),
                  ),
                ),
                style: const TextStyle(fontSize: 14),
                onChanged: (value) => _updateCustomerData(),
              ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 26.0),
                child: SizedBox(
                  width: double.infinity,
                  child: CustomElevatedButton(
                    buttonName: isEditing ? "Actualizar Cliente" : "Crear Cliente",
                    showToast: _handleSave,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
