import 'package:flutter/material.dart';
import 'package:teki_app/src/presentation/screens/purchase/purchase_sections/purchase_return_list_section.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/search_field/custom_search_field.dart';

class PurchaseReturnSection extends StatelessWidget {
  const PurchaseReturnSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(navigateName: "Purchase Return"),
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
                child: CustomSearchField(hintText: "Search Return Purchase")),
            SizedBox(
              height: 20,
            ),
            Expanded(child: PurchaseReturnListSection())
          ],
        ),
      ),
    );
  }
}
