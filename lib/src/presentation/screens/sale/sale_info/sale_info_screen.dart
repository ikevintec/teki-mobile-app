import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/data/static/lists.dart';
import 'package:teki_app/src/presentation/screens/sale/sale_info/widget/otros_datos.dart';
import 'package:teki_app/src/presentation/screens/sale/sale_info/widget/payment_widget.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/modal/custom_modal.dart';
import 'package:teki_app/src/presentation/widgets/segment/custom_segment_selector.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/providers/auth/login.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/providers/tickets_sale/tickets_sale_provider.dart';
import 'package:teki_app/src/utils/contstants.dart';

class SaleInfoScreen extends ConsumerStatefulWidget {
  const SaleInfoScreen({super.key});

  @override
  ConsumerState<SaleInfoScreen> createState() => _SaleInfoScreenState();
}

class _SaleInfoScreenState extends ConsumerState<SaleInfoScreen> {
  String tipoDocumento = "NV"; // Boleta
  String vendedor = "";
  List<String> seriesDisponibles = [];
  String? selectedSerie;
  String? numeroCorrelativo;
  TextEditingController numeroController = TextEditingController();
  TextEditingController vendedorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Inicializar el tipo de documento y cargar las series disponibles
      final notifier = ref.read(ticketProvider.notifier);
      final provider = ref.read(ticketProvider);
      final comprobante = provider.ticket.tipoComprobante ?? tipoDocumento;
      notifier.setTipoComprobante(comprobante);
      notifier.setFechaEmision(DateTime.now()); // Fecha de emisión por defecto
      tipoDocumento = comprobante;

      _dateController.text = DateTime.now().toString().split(" ")[0];
      cargarSeries();
      setVendedor();
    });
  }

  List<Map<String, String>> tipoOperacionLista = tipoComprobantesVenta;

  void cargarSeries() async {
    await ref.read(ticketSaleProvider.notifier).obtenerNumerosSeries();
    final ticketSaleProviderData = ref.read(ticketSaleProvider);

    final series = ticketSaleProviderData.numeros;
    selectedSerie = series.isNotEmpty ? series.first : null;

    if (selectedSerie != null) {
      ref.read(ticketProvider.notifier).setSerie(selectedSerie!);
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
        ref.read(ticketProvider.notifier).setFechaVencimiento(_picked);
      });
    }
  }

  void cargarNextNumber() async {
    await ref.read(ticketSaleProvider.notifier).getNextTicketNumber();
    final actualNumber = ref.read(ticketProvider).ticket.numero;
    if (actualNumber != null) {
      setState(() {
        numeroCorrelativo = actualNumber.toString();
        numeroController.text = numeroCorrelativo ?? '';
      });
    }
  }
  void setVendedor() {
    final vendedor = ref.read(authStateProvider).user?.name ?? '';
    final id = ref.read(authStateProvider).user?.id ?? 0;
    setState(() {
      this.vendedor = vendedor;
      ref.read(ticketProvider.notifier).setVendedor(User(name: vendedor,id: id));
    });
  }

  TextEditingController _dateController = TextEditingController();
  TextEditingController _dateController2 = TextEditingController();

  String? tipoOperacionSelected = "0101";
  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(ticketProvider.notifier);
    final provider = ref.watch(ticketProvider);
    final saleProvider = ref.watch(ticketSaleProvider);
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
                                  child: CustomSegmentedSelectorMapped(
                                    label: "Tipo de comprobante (*)",
                                    dataSource: tipoComprobantesVenta,
                                    labelKey: "label",
                                    valueKey: "value",
                                    initialValue:
                                        provider.ticket.tipoComprobante ??
                                            tipoDocumento,
                                    onChanged: (value) {
                                      notifier.setTipoComprobante(value);
                                      tipoDocumento = value;
                                      if (value == "NV") {
                                        tipoOperacionSelected = "";
                                      } else {
                                        tipoOperacionSelected = "0101";
                                      }

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
                                    items: saleProvider.numeros,
                                    selectionItem: provider.ticket.serie,
                                    onChanged: (value) {
                                      notifier.setSerie(value ?? '');
                                      cargarNextNumber();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFieldSection(
                                    label: "Número (*)",
                                    hint: "Número correlativo",
                                    inputType: TextInputType.number,
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
                                        onTap: () {},
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                    height: tipoDocumento == "NV" ? 15 : 20),
                                if (tipoDocumento != "NV")
                                  DropdownFormFieldSection(
                                    label: "TIPO OPREACIÓN (*)",
                                    hint: "Selecciona el tipo de operación",
                                    itemsMap: tipoOperacion,
                                    labelKey: "label",
                                    valueKey: "value",
                                    selectionItem: tipoOperacionSelected,
                                    onChanged: (value) {
                                      setState(() {
                                        tipoOperacionSelected = value;
                                        notifier.setTipoOperacion(value ?? '');
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
                                    inputType: TextInputType.number,
                                    onChanged: (value) {
                                      notifier.setNumeroOrden(value);
                                    },
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
                              ref.read(ticketProvider.notifier).setTicketsData();
                              showCustomModal(context:context,child: PaymentWidget(),tittle:  '', showButtoms: false,scrolleable: false, allowButtons: true);
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
