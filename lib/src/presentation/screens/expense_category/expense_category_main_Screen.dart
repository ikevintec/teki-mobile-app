import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/expense_model/expense_category_model.dart';
import 'package:teki_app/src/presentation/screens/expense_category/expense_category_sections/expense_category_list_section.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/button/custom_elevated_button.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';

import 'package:teki_app/src/presentation/widgets/toast/success_toast.dart';

class ExpenseCategoryMainScreen extends StatefulWidget {
  const ExpenseCategoryMainScreen({super.key});

  @override
  State<ExpenseCategoryMainScreen> createState() =>
      _ExpenseCategoryMainScreenState();
}

class _ExpenseCategoryMainScreenState extends State<ExpenseCategoryMainScreen> {
  List<Map<String, dynamic>> expenseCategoryList =
      List.from(expenseCategoryModel);

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: const PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: CustomAppBar(
            navigateName: "Expense Category",
          )),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(
              height: 20,
            ),
            const TextFieldSection(
                label: "Category",
                hint: "Enter Category",
                inputType: TextInputType.text),
            const SizedBox(
              height: 20,
            ),
            const TextFieldSection(
                label: "Sub Category",
                hint: "Enter Sub Category",
                inputType: TextInputType.text),
            const SizedBox(
              height: 20,
            ),
            CustomElevatedButton(
                buttonName: "Create Category",
                showToast: () {
                  SuccessToast.showSuccessToast(
                      context, "Create Complete", "Category Create Complete");
                }),
            const SizedBox(
              height: 40,
            ),
            Text(
              "Expense Categories",
              style: GoogleFonts.raleway(
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            Expanded(
                child: ExpenseCategoryListSection(
              isSmallScreen: isSmallScreen,
              categoryList: expenseCategoryList,
            )),
          ],
        ),
      ),
    );
  }
}
