// ignore_for_file: unrelated_type_equality_checks

import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:salespro_saas_admin/Screen/Dashboard/dashboard.dart';

import '../../Reports/reports.dart';
import '../../Shop Category/shop_category.dart';
import '../../Shop Management/shop_management.dart';
import '../Constant Data/constant.dart';

List<String> titleList = [
  'Dashboard',
  'Shop List',
  'Shop Category',
  'Reports',
];

String selected = 'Dashboard';

List<IconData> iconList = [
  Icons.dashboard,
  Icons.home_work,
  FeatherIcons.box, FontAwesomeIcons.fileLines,
];

List<String> screenList = [
  MtDashboard.route,
  ShopManagement.route,
  ShopCategory.route,
  Reports.route,
];

List<String> tabletScreenList = [
  '/',
  MtDashboard.route,
  MtDashboard.route,
  MtDashboard.route,
  MtDashboard.route,
  MtDashboard.route,
];

class SideBarWidget extends StatelessWidget {
  const SideBarWidget({Key? key, required this.index, required this.isTab}) : super(key: key);
  final int index;
  final bool isTab;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(color: kDarkGreyColor),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(color: kDarkGreyColor),
                child: ListTile(
                  leading: const CircleAvatar(
                    radius: 16.0,
                    backgroundImage: AssetImage('images/salespro.jpg'),
                  ),
                  title: Text(
                    'SalesPro',
                    style: kTextStyle.copyWith(color: kWhiteTextColor),
                  ),
                  trailing: const Icon(
                    FeatherIcons.chevronRight,
                    color: Colors.white,
                    size: 18.0,
                  ),
                ),
              ),
              const Divider(
                thickness: 1.0,
                color: kGreyTextColor,
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: titleList.length,
                itemBuilder: (_, i) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        color: index == i ? kBlueTextColor : null,
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            selectedTileColor: kBlueTextColor,
                            onTap: (() {
                              screenList[i] == Navigator.of(context).pushNamed(isTab ? tabletScreenList[i] : screenList[i]);
                              // screenList[i].launch(context);
                              selected = titleList[i];
                            }),
                            leading: Icon(iconList[i], color: kWhiteTextColor),
                            title: Text(
                              titleList[i],
                              style: kTextStyle.copyWith(color: kWhiteTextColor),
                            ),
                            trailing: const Icon(
                              FeatherIcons.chevronRight,
                              color: Colors.white,
                              size: 18.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 50.0,),
              Text('Salespro SAAS',style: kTextStyle.copyWith(color: Colors.white,fontWeight: FontWeight.bold),),
              Text('Version 1.0.0',style: kTextStyle.copyWith(color: Colors.white,fontWeight: FontWeight.bold),)
            ],
          ),
        ),
      ),
    );
  }
}
