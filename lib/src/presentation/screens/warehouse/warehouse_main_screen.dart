import 'package:flutter/material.dart';
import 'package:teki_app/src/presentation/screens/warehouse/warehouse_sections/warehouse_list_section.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/floating_action_button/custom_floating_action_button.dart';
import 'package:teki_app/src/presentation/widgets/search_field/custom_search_field.dart';
import 'package:teki_app/src/routes/app_routes.dart';

class WarehouseMainScreen extends StatelessWidget {
  const WarehouseMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(navigateName: "Warehouse"),
      ),
      body: Container(
        color: Colors.white70,
        child: const Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: CustomSearchField(hintText: "Search Warehouse"),
            ),
            SizedBox(
              height: 20,
            ),
            Expanded(child: WarehouseListSection()),
          ],
        ),
      ),
      floatingActionButton: const CustomFloatingActionButton(
        buttonName: "Add Warehouse",
        routeName: AppRoutes.addWarehouse,
      ),
    );
  }
}
