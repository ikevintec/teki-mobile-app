import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/screens/sale/sale_info/widget/otros_datos.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/segment/custom_segment_selector.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/providers/auth/login.dart';
import 'package:teki_app/src/providers/tickets_sale/tickets_sale_provider.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/providers/config/config.dart';

class SaleInfoScreen extends ConsumerStatefulWidget {
  const SaleInfoScreen({super.key});

  @override
  ConsumerState<SaleInfoScreen> createState() => _SaleInfoScreenState();
}

class _SaleInfoScreenState extends ConsumerState<SaleInfoScreen> {
  List<String> productTypeLote = ["Boleta", "Factura", "N. credito"];
  String selectedType = "Boleta";
  String tipoDocumento = "03";
  String vendedor = "";
  List<String> seriesDisponibles = [];
  String? selectedSerie;
  String? numeroCorrelativo;
  TextEditingController numeroController = TextEditingController();
  TextEditingController vendedorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    tipoDocumento = "03";
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dateController.text = DateTime.now().toString().split(" ")[0];
      cargarSeries();
    });
  }

  void cargarSeries() async {
    final user = ref.watch(authStateProvider).user;
    final userName = user?.name ?? "User Name";
    vendedor = userName;

    final officeId = ref.read(sesionProvider).office?.id;
    if (officeId == null) return;

    final ticketNotifier = ref.read(ticketSaleProvider.notifier);
    final series =
        await ticketNotifier.obtenerNumerosSeries(officeId, tipoDocumento);

    setState(() {
      seriesDisponibles = series;
      selectedSerie = series.isNotEmpty ? series.first : null;
    });

    if (selectedSerie != null) {
      cargarNextNumber();
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? _picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (_picked != null) {
      setState(() {
        _dateController2.text = _picked.toString().split(" ")[0];
      });
    }
  }

  void cargarNextNumber() async {
    final ticketNotifier = ref.read(ticketSaleProvider.notifier);
    final ticket =
        await ticketNotifier.getNextTicketNumber(tipoDocumento, selectedSerie!);
    if (ticket != null) {
      setState(() {
        numeroCorrelativo = ticket.numero?.toString();
        numeroController.text = numeroCorrelativo ?? '';
      });
    }
  }

  TextEditingController _dateController = TextEditingController();
  TextEditingController _dateController2 = TextEditingController();

  final Map<String, String> currencyMap = {
    "Soles": "PEN",
    "Dólares": "USD",
    "Euros": "EUR",
  };
  final List<String> items = ["Soles", "Dólares", "Euros"];
  String? selectedDisplay = "Soles"; // lo que se muestra
  String? selectedValue = "PEN"; // lo que se guarda internamente

  final Map<String, String> currencyMap2 = {
    "Venta Interna [0101]": "0101",
    "Exportación [0200]": "0200",
    "Opreración Sujeta a Detracción [1001]": "1001",
    "Opreración Sujeta a Percepción [2001]": "2001",
  };
  final List<String> itemsOperacion = [
    "Venta Interna [0101]",
    "Exportación [0200]",
    "Opreración Sujeta a Detracción [1001]",
    "Opreración Sujeta a Percepción [2001]"
  ];
  String? selectedDisplay2 = "Venta Interna [0101]"; // lo que se muestra
  String? selectedValue2 = "0101"; // lo que se guarda internamente
  @override
  Widget build(BuildContext context) {
    // final config = ref.watch(sesionProvider);
    ref.read(ticketSaleProvider.notifier);
    //final ticketState = ref.watch(ticketSaleProvider);
    // String? _selectedCurrency;
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
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
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
                                        switch (value) {
                                          case "Boleta":
                                            tipoDocumento = "03";
                                            selectedValue2 = "0101";
                                            break;
                                          case "Factura":
                                            tipoDocumento = "01";
                                            break;
                                          case "N. credito":
                                            tipoDocumento = "NV";
                                            selectedValue2 = "";
                                            break;
                                        }
                                      });
                                      cargarSeries();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 25),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownFormFieldSection(
                                    label: "Serie (*)",
                                    hint: "Selecciona una serie",
                                    items: seriesDisponibles,
                                    selectionItem: selectedSerie,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedSerie = value;
                                      });
                                      cargarNextNumber();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFieldSection(
                                    label: "Número (*)",
                                    hint: "Número correlativo",
                                    inputType: TextInputType.phone,
                                    controller: numeroController,
                                    onChanged: (value) {},
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Campo requerido';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 15),
                            //FECHAS
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "  FECHA(*)",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(
                                          height:
                                              6), // espacio entre label y campo
                                      TextField(
                                        controller: _dateController,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white,
                                          prefixIcon: const Icon(
                                              Icons.calendar_today,
                                              size: 20),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 12, horizontal: 16),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            borderSide: const BorderSide(
                                                color: Colors.grey),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            borderSide: const BorderSide(
                                                color: Colors.black),
                                          ),
                                        ),
                                        style: const TextStyle(fontSize: 14),
                                        readOnly: true,
                                        onTap: null,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "  VENCIMIENTO",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(
                                          height:
                                              6), // espacio entre label y campo
                                      TextField(
                                        controller: _dateController2,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white,
                                          prefixIcon: const Icon(
                                              Icons.calendar_today,
                                              size: 20),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 12, horizontal: 16),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            borderSide: const BorderSide(
                                                color: Colors.grey),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            borderSide: const BorderSide(
                                                color: Colors.black),
                                          ),
                                        ),
                                        style: const TextStyle(fontSize: 14),
                                        readOnly: true,
                                        onTap: _selectDate,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            DropdownFormFieldSection(
                              label: "MONEDA (*)", // Sin etiqueta externa
                              hint: "Selecciona la moneda",
                              items:
                                  items, // Lista de monedas visibles: ['Soles', 'Dólares', 'Euros']
                              selectionItem: selectedDisplay,
                              onChanged: (value) {
                                setState(() {
                                  selectedDisplay = value;
                                  selectedValue =
                                      currencyMap[value]; // 'pen', 'usd', 'eur'
                                });
                              },
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                    height: tipoDocumento == "NV" ? 15 : 20),
                                if (tipoDocumento != "NV")
                                  DropdownFormFieldSection(
                                    label: "TIPO OPREACIÓN (*)",
                                    hint: "Selecciona el tipo de operación",
                                    items: itemsOperacion,
                                    selectionItem: selectedDisplay2,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedDisplay2 = value;
                                        selectedValue2 = currencyMap2[value];
                                      });
                                    },
                                  ),
                                SizedBox(
                                    height: tipoDocumento == "NV" ? 0 : 20),
                              ],
                            ),
                            Row(
                              children: [
                                // Campo VENDEDOR solo lectura
                                Expanded(
                                  flex: 1,
                                  child: TextFieldSection(
                                    label: "VENDEDOR",
                                    hint: "Vendedor",
                                    controller:
                                        TextEditingController(text: vendedor),
                                    inputType: TextInputType.text,
                                    isReadOnly: true,
                                    onChanged: (_) {},
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // Campo N. ORDEN editable
                                Expanded(
                                  flex: 1,
                                  child: TextFieldSection(
                                    label: "N. ORDEN",
                                    hint: "N. Orden",
                                    controller: vendedorController,
                                    inputType: TextInputType.phone,
                                    onChanged: (_) {},
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            OtherOptions(),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              print("✅ Series disponibles: $selectedSerie");
                              print("✅ Número: ${numeroController.text}");
                              print("Moneda seleccionada: $selectedValue");
                              print("Fecha Inicio: ${_dateController.text}");
                              print(
                                  "Fecha Vencimiento: ${_dateController2.text}");
                              print("✅ Tipo Opreacion: $selectedValue2");
                              print("✅ Vendedor: $vendedor");
                              print("✅ N. Orden: ${vendedorController.text}");
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
                                Text('Confirmar'),
                                SizedBox(width: 8),
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

  DropdownMenuItem<String> buildMenuItem(String item) => DropdownMenuItem(
        value: item,
        child: Text(
          item,
          style: const TextStyle(fontSize: 15),
        ),
      );

  DropdownMenuItem<String> buildMenuItem2(String itemsOperacion) =>
      DropdownMenuItem(
        value: itemsOperacion,
        child: Text(
          itemsOperacion,
          style: const TextStyle(fontSize: 15),
        ),
      );
}

DropdownMenuItem<String> buildMenuItem(String items) => DropdownMenuItem(
      value: items,
      child: Text(
        items,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );

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
      return StatefulBuilder(
        builder: (context, setState) {
          return OtrosDatosWidget();
        },
      );
    },
  );
}

