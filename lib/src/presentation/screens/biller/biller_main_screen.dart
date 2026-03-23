import 'package:flutter/material.dart';
import 'package:teki_app/src/presentation/screens/biller/biller_sections/biller_list_section.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/floating_aciton_button/custom_floating_action_button.dart';
import 'package:teki_app/src/presentation/widgets/search_field/custom_search_Field.dart';
import 'package:teki_app/src/routes/app_routes.dart';

class BillerMainScreen extends StatelessWidget {
  const BillerMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(navigateName: "Biller"),
      ),
      body: Container(
        color: Colors.white,
        child: const Column(
          children: [
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: CustomSearchField(hintText: "Search Biller"),
            ),
            SizedBox(
              height: 20,
            ),
            Expanded(child: BillerListSection())
          ],
        ),
      ),
      floatingActionButton: const CustomFloatingActionButton(
          buttonName: "Create Biller", routeName: AppRoutes.createBiller),
    );
  }
}
