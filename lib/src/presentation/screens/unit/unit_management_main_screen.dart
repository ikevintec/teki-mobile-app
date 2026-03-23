import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/products_model/product_unit_model.dart';
import 'package:teki_app/src/presentation/screens/unit/unit_management_sections/update_unit_management_screen.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/button/custom_elevated_button.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/delete_toast.dart';
import 'package:teki_app/src/presentation/widgets/toast/success_toast.dart';

class UnitManagementMainScreen extends StatefulWidget {
  const UnitManagementMainScreen({super.key});

  @override
  State<UnitManagementMainScreen> createState() =>
      _UnitManagementMainScreenState();
}

class _UnitManagementMainScreenState extends State<UnitManagementMainScreen> {
  List<Map<String, dynamic>> unitList = List.from(productUnitModel);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: CustomAppBar(
            navigateName: "Unit Management",
          )),
      body: Container(
        color: Colors.white70,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(
              height: 20,
            ),
            const TextFieldSection(
                label: "Unit-Name",
                hint: "Enter Unit Name",
                inputType: TextInputType.name),
            const SizedBox(
              height: 20,
            ),
            const TextFieldSection(
                label: "Unit-Short-Name",
                hint: "Enter Unit Short Name",
                inputType: TextInputType.name),
            const SizedBox(
              height: 20,
            ),
            CustomElevatedButton(
                buttonName: "Create Unit",
                showToast: () {
                  SuccessToast.showSuccessToast(
                      context, "Create Complete", "Unit Create Complete");
                }),
            const SizedBox(height: 40),
            Text(
              "Existing Units",
              style: GoogleFonts.raleway(
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(
              height: 10,
            ),
            Expanded(
                child: ListView.separated(
              itemCount: unitList.length,
              separatorBuilder: (context, index) => const SizedBox(
                height: 15,
                child: Divider(
                  color: Color(0xFFE2E4E7),
                ),
              ),
              itemBuilder: (context, index) {
                var unit = unitList[index];
                return ListTile(
                  title: Text(
                    unit["unit-name"],
                    style: GoogleFonts.raleway(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      unit["unit-short-name"],
                      style: GoogleFonts.nunito(color: Colors.grey),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          color: Colors.blue.shade50.withOpacity(0.3),
                        ),
                        child: IconButton(
                          onPressed: () {
                            buildModalBottomSheet(context, unit);
                          },
                          icon: SvgPicture.asset(
                            "assets/icons/icon_svg/edit_icon.svg",
                            color: Colors.blue,
                            width: 18,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          color: Colors.red.shade50.withOpacity(0.3),
                        ),
                        child: IconButton(
                          onPressed: () {
                            DeleteToast.showDeleteToast(
                                context, unit["unit-name"]);

                            setState(() {
                              unitList.removeAt(index);
                            });
                          },
                          icon: SvgPicture.asset(
                            "assets/icons/icon_svg/delete_icon.svg",
                            color: Colors.red,
                            width: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ))
          ],
        ),
      ),
    );
  }

  void buildModalBottomSheet(BuildContext context, unit) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      elevation: 0,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      context: context,
      builder: (_) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: UpdateUnitManagementScreen(unit: unit),
        );
      },
    );
  }
}
