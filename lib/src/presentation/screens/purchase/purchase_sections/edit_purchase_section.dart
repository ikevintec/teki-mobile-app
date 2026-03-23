import 'package:flutter/material.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/button/custom_elevated_button.dart';
import 'package:teki_app/src/presentation/widgets/date_picker_section/date_picker.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/success_toast.dart';

class EditPurchaseSection extends StatelessWidget {
  final dynamic purchase;

  const EditPurchaseSection({super.key, required this.purchase});

  @override
  Widget build(BuildContext context) {
    const warehouseSelectedValue = "";

    List<String> warehouseItems = [
      "Warehouse 1",
      "Warehouse 2",
      "Warehouse 3",
      "Warehouse 4",
      "Warehouse 5"
    ];

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(
          navigateName: "Edit Purchase",
        ),
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView(
          children: [
            const SizedBox(
              height: 20,
            ),
            DatePicker(
              labelText: "Date",
              hintText: purchase.value["date"],
            ),
            const SizedBox(
              height: 20,
            ),
            TextFieldSection(
                label: "Supplier Name",
                hint: purchase.value["supplierName"],
                inputType: TextInputType.name),
            const SizedBox(
              height: 20,
            ),
            TextFieldSection(
                label: "Reference",
                hint: purchase.value["reference"],
                inputType: TextInputType.text),
            const SizedBox(
              height: 20,
            ),
            TextFieldSection(
              label: "Status",
              hint: purchase.value["status"],
              inputType: TextInputType.text,
            ),
            const SizedBox(
              height: 20,
            ),
            TextFieldSection(
              label: "Payment",
              hint: purchase.value["payment"],
              inputType: TextInputType.text,
            ),
            const SizedBox(
              height: 20,
            ),
            TextFieldSection(
              label: "Grand Total",
              hint: purchase.value["grandTotal"],
              inputType: TextInputType.number,
            ),
            const SizedBox(
              height: 20,
            ),
            TextFieldSection(
              label: "Paid",
              hint: purchase.value["paid"],
              inputType: TextInputType.number,
            ),
            const SizedBox(
              height: 20,
            ),
            TextFieldSection(
                label: "Due",
                hint: purchase.value["due"],
                inputType: TextInputType.number),
            const SizedBox(
              height: 20,
            ),
            DropdownFormFieldSection(
                label: "Warehouse",
                hint: purchase.value["warehouse"],
                items: warehouseItems,
                selectionItem: warehouseSelectedValue),
            const SizedBox(
              height: 20,
            ),
            CustomElevatedButton(
                buttonName: "Update",
                showToast: () {
                  SuccessToast.showSuccessToast(
                      context, "Update Complete", "Purchase Update Complete");
                }),
            const SizedBox(
              height: 20,
            )
          ],
        ),
      ),
    );
  }
}
