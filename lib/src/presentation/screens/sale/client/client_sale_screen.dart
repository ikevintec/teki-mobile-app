import 'package:flutter/material.dart';
import 'package:teki_app/src/presentation/screens/sale/sale_info/sale_info_screen.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/utils/contstants.dart';

class ClientSaleScreen extends StatelessWidget {
  const ClientSaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(
          navigateName: "Cliente",
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
                      topRight: Radius.circular(40)),
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
                            TextFieldSection(
                              label: "Nombre",
                              hint: "Nombre",
                              inputType: TextInputType.number,
                              onChanged: (value) {},
                            ),
                            const SizedBox(height: 30),
                            DropdownFormFieldSection(
                              label: "Tipo documento",
                              hint: "Selecciona un tipo documento",
                              items: ["DNI", "RUC", "Pasaporte"],
                              selectionItem: "DNI",
                            ),
                            const SizedBox(height: 30),
                            TextFieldSection(
                              label: "Numero Documento",
                              hint: "Numero Documento",
                              inputType: TextInputType.number,
                              onChanged: (value) {},
                            ),
                            const SizedBox(height: 30),
                            TextFieldSection(
                              label: "Direccion fiscal",
                              hint: "Direccion fiscal",
                              inputType: TextInputType.number,
                              onChanged: (value) {},
                            ),
                            const SizedBox(height: 30),
                            TextFieldSection(
                              label: "Email",
                              hint: "Email",
                              inputType: TextInputType.number,
                              onChanged: (value) {},
                            ),
                            const SizedBox(height: 30),
                            TextFieldSection(
                              label: "Telefono",
                              hint: "Telefono",
                              inputType: TextInputType.number,
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
                                    builder: (context) => SaleInfoScreen()),
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
