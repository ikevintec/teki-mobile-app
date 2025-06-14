import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/segment/custom_segment_selector.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/utils/contstants.dart';

class SaleInfoScreen extends StatefulWidget {
  const SaleInfoScreen({super.key});

  @override
  State<SaleInfoScreen> createState() => _SaleInfoScreenState();
}

class _SaleInfoScreenState extends State<SaleInfoScreen> {
  List<String> productTypeLote = ["Boleta", "Factura", "Nota de credito"];
  String selectedType = "Boleta";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(
          navigateName: "Comprobante",
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
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                color: ColorSchema.primaryColor,
                                size: 70,
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: CustomSegmentedSelector(
                                  label: "Tipo de comprobante (*)",
                                  options: productTypeLote,
                                  selected: selectedType,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedType = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownFormFieldSection(
                                    label: "Serie (*)",
                                    hint: "Selecciona un tipo documento",
                                    items: ["P001", "RUC", "Pasaporte"],
                                    selectionItem: "P001"),
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                child: TextFieldSection(
                                  label: "Numero",
                                  hint: "Razon social",
                                  inputType: TextInputType.number,
                                  onChanged: (value) {},
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownFormFieldSection(
                                    label: "Fecha (*)",
                                    hint: "Selecciona un tipo documento",
                                    items: ["P001", "RUC", "Pasaporte"],
                                    selectionItem: "P001"),
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                child: TextFieldSection(
                                  label: "Vencimiento",
                                  hint: "Razon social",
                                  inputType: TextInputType.number,
                                  onChanged: (value) {},
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          DropdownFormFieldSection(
                              label: "Tipo de operacion(*)",
                              hint: "Selecciona un tipo documento",
                              items: ["P001", "RUC", "Pasaporte"],
                              selectionItem: "P001"),
                          const SizedBox(height: 20),
                          OtherOptions(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    )),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  ColorSchema.primaryColor, // 🔵 Color de fondo
                              foregroundColor:
                                  Colors.white, // ⚪ Color del texto y del icono
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12), // altura del botón
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    12), // 🎯 Bordes redondeados
                              ),
                              elevation: 2, // sombra
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize
                                  .min, // Para que no se estire innecesariamente
                              children: [
                                Text('Confirmar'),
                                SizedBox(
                                    width: 8), // Espacio entre texto e ícono
                                Icon(Icons.check_circle),
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

class OtherOptions extends StatelessWidget {
  const OtherOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showOtrosDatosModal(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ColorSchema.primaryColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Otros datos",
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ColorSchema.primaryColor,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.more_horiz,
              color: ColorSchema.primaryColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

void showOtrosDatosModal(BuildContext context) {
  showGeneralDialog(
    barrierLabel: "Otros Datos",
    barrierDismissible: false,
    transitionDuration: const Duration(milliseconds: 200),
    context: context,
    pageBuilder: (context, anim1, anim2) {
      return Stack(
        children: [
          // Fondo desenfocado
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              color: Colors.black
                  .withOpacity(0.1), // sin color para solo desenfocar
            ),
          ),
          // Diálogo
          Center(
            child: Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                width: double.maxFinite,
                height: 550,
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: ColorSchema.primaryColor,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: ColorSchema.primaryColor,
                        tabs: [
                          Tab(text: "Guías"),
                          Tab(text: "Otros"),
                          Tab(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text("Observación"),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // TAB 1: Guías
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 25, right: 10, top: 8, bottom: 0),
                              child: Column(
                                children: [
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: GestureDetector(
                                      onTap: () {},
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text("Agregar",
                                              style: GoogleFonts.nunito(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: ColorSchema.primaryColor,
                                              )),
                                          const Icon(Icons.add,
                                              color: ColorSchema.primaryColor,
                                              size: 15),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: 8,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4.0),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: TextFieldSection(
                                                  label: "Nombre",
                                                  hint: "Razon social",
                                                  inputType:
                                                      TextInputType.number,
                                                  onChanged: (value) {},
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: DropdownFormFieldSection(
                                                  label: "Tipo",
                                                  hint:
                                                      "Selecciona un tipo documento",
                                                  items: [
                                                    "P001",
                                                    "RUC",
                                                    "Pasaporte"
                                                  ],
                                                  selectionItem: "P001",
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.close,
                                                    color: Colors.red,
                                                    size: 15),
                                                onPressed: () {},
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // TAB 2: Otros
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 25, right: 10, top: 8, bottom: 0),
                              child: Column(
                                children: [
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: GestureDetector(
                                      onTap: () {},
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text("Agregar",
                                              style: GoogleFonts.nunito(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: ColorSchema.primaryColor,
                                              )),
                                          const Icon(Icons.add,
                                              color: ColorSchema.primaryColor,
                                              size: 15),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: 4,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4.0),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: TextFieldSection(
                                                  label: "Nombre",
                                                  hint: "Razon social",
                                                  inputType:
                                                      TextInputType.number,
                                                  onChanged: (value) {},
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: DropdownFormFieldSection(
                                                  label: "Descripcion",
                                                  hint:
                                                      "Selecciona un tipo documento",
                                                  items: [
                                                    "P001",
                                                    "RUC",
                                                    "Pasaporte"
                                                  ],
                                                  selectionItem: "P001",
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.close,
                                                    color: Colors.red,
                                                    size: 15),
                                                onPressed: () {},
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // TAB 3: Finales
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 25, right: 10, top: 8, bottom: 0),
                              child: Column(
                                children: [
                                  Icon(Icons.more_horiz,
                                      color: ColorSchema.primaryColor,
                                      size: 30),
                                  const SizedBox(height: 10),
                                  TextFieldSection(
                                    label: "Observacion",
                                    hint: "Razon social",
                                    inputType: TextInputType.number,
                                    onChanged: (value) {},
                                  ),
                                  const SizedBox(height: 20),
                                  TextFieldSection(
                                    label: "Otros tributos",
                                    hint: "Razon social",
                                    inputType: TextInputType.number,
                                    onChanged: (value) {},
                                  ),
                                  const SizedBox(height: 20),
                                  TextFieldSection(
                                    label: "N. cotización",
                                    hint: "Razon social",
                                    inputType: TextInputType.number,
                                    onChanged: (value) {},
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 25, right: 10, top: 2, bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                              ),
                              child: const Text(
                                "Cancelar",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 20),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorSchema.primaryColor,
                              ),
                              child: const Text(
                                "Aceptar",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
