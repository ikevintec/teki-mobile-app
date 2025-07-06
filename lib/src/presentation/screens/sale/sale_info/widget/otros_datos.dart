import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/teki_model/aditionalField.dart';
import 'package:teki_app/src/data/models/teki_model/guiaRelacionada.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/providers/tickets_sale/tickets_sale_provider.dart';
import 'package:teki_app/src/utils/contstants.dart';

class OtrosDatosWidget extends ConsumerStatefulWidget {
  const OtrosDatosWidget({super.key});

  @override
  ConsumerState<OtrosDatosWidget> createState() => _OtrosDatosWidgetState();
}

class _OtrosDatosWidgetState extends ConsumerState<OtrosDatosWidget>
    with SingleTickerProviderStateMixin {
  //Datos
  TextEditingController observacion = TextEditingController();
  TextEditingController otrosTributos = TextEditingController();
  TextEditingController nCotizacion = TextEditingController();
  //Listas
  List<TextEditingController> guiasControllers = [];
  List<TextEditingController> otrosNombreControllers = [];
  List<TextEditingController> otrosValorControllers = [];

  List<AditionalField> otrosCampos = [];

  List<GuiaRelacionada> guiasCampos = [];

  List<Map<String, String>> tiposGuias = [
    {'label': 'Remitente', 'value': '09'},
    {'label': 'Transportista', 'value': '11'}
  ];

  final guiasFormKey = GlobalKey<FormState>();
  final otrosFormKey = GlobalKey<FormState>();
  late TabController _tabController;

  void ResetearCampos() {
    observacion.text = "";
    nCotizacion.text = "";
    otrosTributos.text = "";
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });

    final ticket = ref.read(ticketProvider).ticket;

    if ((ticket.camposAdicionales ?? []).isNotEmpty) {
      otrosCampos = List.from(ticket.camposAdicionales!);
      otrosNombreControllers = otrosCampos
          .map((campo) => TextEditingController(text: campo.nombreCampo))
          .toList();
      otrosValorControllers = otrosCampos
          .map((campo) => TextEditingController(text: campo.valorCampo))
          .toList();
    }

    if ((ticket.guiasRelacionadas ?? []).isNotEmpty) {
      guiasCampos = List.from(ticket.guiasRelacionadas!);
      guiasControllers = guiasCampos
          .map((guia) => TextEditingController(text: guia.serieNumeroGuia))
          .toList();
    }

    if ((ticket.observacion ?? '').isNotEmpty){
      observacion.text = ticket.observacion!;
    }

    if ((ticket.numeroCotizacion ?? '').isNotEmpty){
      nCotizacion.text = ticket.numeroCotizacion!;
    }

    if (((ticket.otrosTributos ?? '').toString()).isNotEmpty){
      otrosTributos.text = ticket.otrosTributos.toString();
    }

  }

  @override
  void dispose() {
    for (final controller in guiasControllers) {
      controller.dispose();
    }
    for (final controller in otrosNombreControllers) {
      controller.dispose();
    }
    for (final controller in otrosValorControllers) {
      controller.dispose();
    }
    observacion.dispose();
    otrosTributos.dispose();
    nCotizacion.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(ticketSaleProvider.notifier);

    return Stack(
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            color: Colors.black.withOpacity(0.1),
          ),
        ),
        Center(
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              width: double.maxFinite,
              height: 550,
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: ColorSchema.primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: ColorSchema.primaryColor,
                    tabs: const [
                      Tab(text: "Guías"),
                      Tab(text: "Otros"),
                      Tab(child: FittedBox(child: Text("Observación"))),
                    ],
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _tabController.index,
                      children: [
                        // TAB 1: GUÍAS
                        Form(
                          key: guiasFormKey,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 25, right: 10, top: 8, bottom: 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        guiasCampos.add(GuiaRelacionada(
                                            codigoTipoGuia: '09',
                                            serieNumeroGuia: ''));
                                        guiasControllers
                                            .add(TextEditingController());
                                      });
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Agregar",
                                          style: GoogleFonts.nunito(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: ColorSchema.primaryColor,
                                          ),
                                        ),
                                        const Icon(Icons.add,
                                            color: ColorSchema.primaryColor,
                                            size: 15),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: List.generate(
                                          guiasCampos.length, (index) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4.0),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: TextFieldSection(
                                                  controller:
                                                      guiasControllers[index],
                                                  label: "Guía de remisión",
                                                  hint: "Guia...",
                                                  inputType: TextInputType.text,
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'Guia requerida';
                                                    }
                                                    return null;
                                                  },
                                                  onChanged: (value) {
                                                    guiasCampos[index] =
                                                        guiasCampos[index]
                                                            .copyWith(
                                                                serieNumeroGuia:
                                                                    value);
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              Expanded(
                                                child: DropdownFormFieldSection(
                                                  label: "Tipo",
                                                  hint: "",
                                                  itemsMap: tiposGuias,
                                                  labelKey: "label",
                                                  valueKey: "value",
                                                  selectionItem: guiasCampos[
                                                              index]
                                                          .codigoTipoGuia ??
                                                      "Guía de remisión - Remitente",
                                                  onChanged: (value) {
                                                    setState(() {
                                                      guiasCampos[
                                                          index] = guiasCampos[
                                                              index]
                                                          .copyWith(
                                                              codigoTipoGuia:
                                                                  value);
                                                    });
                                                  },
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.close,
                                                    color: Colors.red,
                                                    size: 15),
                                                onPressed: () {
                                                  setState(() {
                                                    guiasCampos.removeAt(index);
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // TAB 2: OTROS
                        Form(
                          key: otrosFormKey,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 25, right: 10, top: 8, bottom: 0),
                            child: Column(
                              children: [
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        otrosCampos.add(AditionalField(
                                            nombreCampo: '', valorCampo: '09'));
                                        otrosNombreControllers
                                            .add(TextEditingController());
                                        otrosValorControllers
                                            .add(TextEditingController());
                                      });
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Agregar",
                                          style: GoogleFonts.nunito(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: ColorSchema.primaryColor,
                                          ),
                                        ),
                                        const Icon(Icons.add,
                                            color: ColorSchema.primaryColor,
                                            size: 15),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: List.generate(
                                          otrosCampos.length, (index) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4.0),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: TextFieldSection(
                                                  controller:
                                                      otrosNombreControllers[
                                                          index],
                                                  label: "Nombre",
                                                  hint: "Nombre...",
                                                  inputType: TextInputType.text,
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'Campo requerido';
                                                    }
                                                    return null;
                                                  },
                                                  onChanged: (value) {
                                                    otrosCampos[index] =
                                                        otrosCampos[index]
                                                            .copyWith(
                                                                nombreCampo:
                                                                    value);
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: TextFieldSection(
                                                  controller:
                                                      otrosValorControllers[
                                                          index],
                                                  label: "Descripción",
                                                  hint: "Descripción...",
                                                  inputType: TextInputType.text,
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'Campo requerido';
                                                    }
                                                    return null;
                                                  },
                                                  onChanged: (value) {
                                                    otrosCampos[index] =
                                                        otrosCampos[index]
                                                            .copyWith(
                                                                valorCampo:
                                                                    value);
                                                  },
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.close,
                                                    color: Colors.red,
                                                    size: 15),
                                                onPressed: () {
                                                  setState(() {
                                                    otrosCampos.removeAt(index);
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // TAB 3: OBSERVACIÓN
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 25, right: 10, top: 8, bottom: 0),
                          child: Column(
                            children: [
                              Icon(Icons.more_horiz,
                                  color: ColorSchema.primaryColor, size: 30),
                              const SizedBox(height: 10),
                              TextFieldSection(
                                controller: observacion,
                                label: "Observación",
                                hint: "Observación...",
                                inputType: TextInputType.text,
                                onChanged: (value) {},
                              ),
                              const SizedBox(height: 20),
                              TextFieldSection(
                                controller: otrosTributos,
                                label: "Otros tributos",
                                hint: "Otros tributos...",
                                inputType: TextInputType.number,
                                onChanged: (value) {},
                              ),
                              const SizedBox(height: 20),
                              TextFieldSection(
                                controller: nCotizacion,
                                label: "N. cotización",
                                hint: "N. cotización...",
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
                    padding:
                        const EdgeInsets.only(left: 25, right: 10, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey),
                          child: const Text("Cancelar",
                              style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: () {
                            final guiasValid =
                                guiasFormKey.currentState?.validate() ?? false;
                            final otrosValid =
                                otrosFormKey.currentState?.validate() ?? false;

                            if (guiasValid && otrosValid) {
                              if (!mounted) return;
                              Navigator.pop(context);
                              notifier.setOtrosCampos(
                                  otrosCampos,
                                  guiasCampos,
                                  observacion.text,
                                  nCotizacion.text,
                                  otrosTributos.text);
                              ResetearCampos();
                            } else {
                              if (!guiasValid) {
                                _tabController.animateTo(0);
                              } else if (!otrosValid) {
                                _tabController.animateTo(1);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorSchema.primaryColor,
                          ),
                          child: const Text("Aceptar",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
