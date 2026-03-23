import 'package:flutter/material.dart';
import 'package:teki_app/src/presentation/screens/supplier/supplier_sections/supplier_list_section.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/floating_aciton_button/custom_floating_action_button.dart';
import 'package:teki_app/src/presentation/widgets/search_field/custom_search_Field.dart';
import 'package:teki_app/src/routes/app_routes.dart';

class SupplierMainScreen extends StatelessWidget {
  const SupplierMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(navigateName: "Supplier"),
      ),
      body: Container(
        color: Colors.white70,
        child: const Column(
          children: [
            SizedBox(
              height: 20,
            ),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: CustomSearchField(hintText: "Search Supplier")),
            SizedBox(
              height: 20,
            ),
            Expanded(child: SupplierListSection())
          ],
        ),
      ),
      floatingActionButton: const CustomFloatingActionButton(
          buttonName: "Create Supplier", routeName: AppRoutes.createSupplier),
    );
  }
}
