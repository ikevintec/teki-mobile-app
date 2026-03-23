import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/button/custom_elevated_button.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_action_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/success_toast.dart';
import 'package:teki_app/src/presentation/widgets/upload_image/upload_image.dart';

class AddProductMainScreen extends StatefulWidget {
  const AddProductMainScreen({super.key});

  @override
  State<AddProductMainScreen> createState() => _AddProductMainScreenState();
}

class _AddProductMainScreenState extends State<AddProductMainScreen> {
  String categorySelectedValue = '';
  String brandSelectedValue = '';
  String unitSelectedValue = '';
  String taxSelectedValue = '';
  String taxMethodSelectedValue = '';
  String warehouseSelectedValue = "";

  List<String> categoryItems = ["Computer", "Television", "Shoes", "Fruits"];
  List<String> brandItems = ["Dell", "Acer", "Asus", "Hp", "Lenovo"];
  List<String> taxItems = ["12%", "11%", "10%", "9%", "8%"];
  List<String> taxMethodItems = ["Exclusive", "Non - Exclusive"];
  List<String> unitItems = ["Kilogram", "Meter", "Piece"];
  List<String> warehouseItems = ["Warehouse 1", "Warehouse 2", "Warehouse 3"];
  String img = "assets/images/products/apple_device.png";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: CustomAppBar(
            navigateName: "Add Product",
          )),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.white70,
        child: ListView(
          children: [
            const SizedBox(
              height: 20,
            ),
            UploadImage(image: img,
            onImageSelected: (newImage,file) {
              setState(() {
                img = newImage;
              });
            },
            ),
            const SizedBox(
              height: 20,
            ),
            const TextFieldSection(
                label: "Product",
                hint: "Enter Product Name",
                inputType: TextInputType.name),
            const SizedBox(
              height: 20,
            ),
            DropdownFormFieldActionSection(
                label: "Category",
                hint: "Select Product Category",
                items: categoryItems,
                selectionItem: categorySelectedValue,
                checkValue: "category",
                addTitle: "Add Category"),
            const SizedBox(
              height: 20,
            ),
            DropdownFormFieldActionSection(
                label: "Brand",
                hint: "Select Product Brand",
                items: brandItems,
                selectionItem: brandSelectedValue,
                checkValue: "brand",
                addTitle: "Add Brand"),
            const SizedBox(
              height: 20,
            ),
            DropdownFormFieldActionSection(
                label: "Unit",
                hint: "Select Product Unit",
                items: unitItems,
                selectionItem: unitSelectedValue,
                checkValue: "unit",
                addTitle: "Add Unit"),
            const SizedBox(
              height: 20,
            ),
            DropdownFormFieldSection(
                label: "Warehouse",
                hint: "Select Warehouse",
                items: warehouseItems,
                selectionItem: warehouseSelectedValue),
            const SizedBox(
              height: 20,
            ),
            Row(
              children: [
                const Expanded(
                  flex: 6,
                  child: TextFieldSection(
                      label: "Product Code",
                      hint: "Enter Product Code",
                      inputType: TextInputType.number),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Container(
                        decoration: BoxDecoration(
                            color: const Color(0xFFFCFCFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFE2E4E7), width: 1)),
                        child: SvgPicture.asset(
                          "assets/icons/icon_svg/barcode.svg",
                          width: 55,
                        )))
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            DropdownFormFieldSection(
                label: "Product Tax",
                hint: "Select Product Tax",
                items: taxItems,
                selectionItem: taxSelectedValue),
            const SizedBox(
              height: 20,
            ),
            DropdownFormFieldSection(
              label: "Tax Method",
              hint: "Select Tax Method",
              items: taxMethodItems,
              selectionItem: taxMethodSelectedValue,
            ),
            const SizedBox(
              height: 20,
            ),
            const Row(
              children: [
                Expanded(
                  child: TextFieldSection(
                      label: "Product Price",
                      hint: "Enter Product Price",
                      inputType: TextInputType.number),
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: TextFieldSection(
                      label: "Product Stock",
                      hint: "Enter Product Stock",
                      inputType: TextInputType.number),
                )
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              width: double.maxFinite,
              child: CustomElevatedButton(
                  buttonName: "Submit",
                  showToast: () {
                    SuccessToast.showSuccessToast(
                        context, "Submit Complete", "Product Submit Complete");
                  }),
            ),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}
