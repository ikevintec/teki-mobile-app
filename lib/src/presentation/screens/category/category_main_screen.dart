import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/products_model/products_category_model.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/button/custom_elevated_button.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/success_toast.dart';

class CategoryMainScreen extends StatefulWidget {
  const CategoryMainScreen({super.key});

  @override
  State<CategoryMainScreen> createState() => _CategoryMainScreenState();
}

class _CategoryMainScreenState extends State<CategoryMainScreen> {
  String categorySelectedValue = "";

  List<String> categoryItems = [
    "Fish & Meat",
    "Electronics",
    "Fashion",
    "Accessories",
    "Cosmetics",
    "Gadgets",
    "Physical Goods",
    "Electrical",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(navigateName: "Category"),
      ),
      body: Container(
        color: Colors.white70,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TextFieldSection(
                label: "Sub-Category",
                hint: "Enter Sub Category",
                inputType: TextInputType.name,
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TextFieldSection(
                label: "Main-Category",
                hint: "Enter Main Category",
                inputType: TextInputType.name,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CustomElevatedButton(
                  buttonName: "Create Category",
                  showToast: () {
                    SuccessToast.showSuccessToast(
                        context, "Create Complete", "Category Create Complete");
                  }),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Products Category",
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: productsCategoryModel.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Text(
                        productsCategoryModel[index]["category-name"],
                        style: GoogleFonts.raleway(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: const Color(0xFF444444),
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          productsCategoryModel[index]["category_item"],
                          style: GoogleFonts.nunito(),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
