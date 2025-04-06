import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:salespro_saas_admin/Screen/Widgets/Constant%20Data/button_global.dart';

import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Sidebar/sidebar_widget.dart';
import '../Widgets/Topbar/topbar.dart';

class Package extends StatefulWidget {
  const Package({Key? key}) : super(key: key);

  static const String route = '/package';

  @override
  State<Package> createState() => _PackageState();
}

class _PackageState extends State<Package> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      body: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            flex: 1,
            child: SideBarWidget(
              index: 3,
              isTab: false,
            ),
          ),
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6.0),
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: kWhiteTextColor,
                    ),
                    child: const TopBar(),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: kWhiteTextColor),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PACKAGE',
                                style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 30.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      padding: const EdgeInsets.all(10.0),
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), border: Border.all(color: kBorderColorTextField)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Container(
                                            height: 80,
                                            width: 80,
                                            decoration: const BoxDecoration(
                                              image: DecorationImage(image: AssetImage('images/month.png'), fit: BoxFit.cover),
                                            ),
                                          ),
                                          Text(
                                            '1 Month',
                                            style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 10.0),
                                          Text(
                                            '\$ 200',
                                            style: kTextStyle.copyWith(color: kBlueTextColor, fontWeight: FontWeight.bold, fontSize: 21.0),
                                          ),
                                          const SizedBox(height: 10.0),
                                          Text(
                                            'Our Premium Features',
                                            style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 10.0),
                                          ListTile(
                                            visualDensity: const VisualDensity(vertical: -4),
                                            contentPadding: EdgeInsets.zero,
                                            horizontalTitleGap: 5,
                                            leading: const Icon(
                                              FeatherIcons.check,
                                              color: kBlueTextColor,
                                            ),
                                            title: Text(
                                              'Free Lifetime Update',
                                              style: kTextStyle.copyWith(color: kTitleColor),
                                            ),
                                          ),
                                          ListTile(
                                            visualDensity: const VisualDensity(vertical: -4),
                                            contentPadding: EdgeInsets.zero,
                                            horizontalTitleGap: 5,
                                            leading: const Icon(
                                              FeatherIcons.check,
                                              color: kBlueTextColor,
                                            ),
                                            title: Text(
                                              'Android & iOS App Support',
                                              style: kTextStyle.copyWith(color: kTitleColor),
                                            ),
                                          ),
                                          ListTile(
                                            visualDensity: const VisualDensity(vertical: -4),
                                            contentPadding: EdgeInsets.zero,
                                            horizontalTitleGap: 5,
                                            leading: const Icon(
                                              FeatherIcons.check,
                                              color: kBlueTextColor,
                                            ),
                                            title: Text(
                                              'Premium Customer Support',
                                              style: kTextStyle.copyWith(color: kTitleColor),
                                            ),
                                          ),
                                          ListTile(
                                            visualDensity: const VisualDensity(vertical: -4),
                                            contentPadding: EdgeInsets.zero,
                                            horizontalTitleGap: 5,
                                            leading: const Icon(
                                              FeatherIcons.check,
                                              color: kBlueTextColor,
                                            ),
                                            title: Text(
                                              'Custom Invoice Branding',
                                              style: kTextStyle.copyWith(color: kTitleColor),
                                            ),
                                          ),
                                          ListTile(
                                            visualDensity: const VisualDensity(vertical: -4),
                                            contentPadding: EdgeInsets.zero,
                                            horizontalTitleGap: 5,
                                            leading: const Icon(
                                              FeatherIcons.check,
                                              color: kBlueTextColor,
                                            ),
                                            title: Text(
                                              'Unlimited Usage',
                                              style: kTextStyle.copyWith(color: kTitleColor),
                                            ),
                                          ),
                                          ListTile(
                                            visualDensity: const VisualDensity(vertical: -4),
                                            contentPadding: EdgeInsets.zero,
                                            horizontalTitleGap: 5,
                                            leading: const Icon(
                                              FeatherIcons.check,
                                              color: kBlueTextColor,
                                            ),
                                            title: Text(
                                              'Free Data Backup',
                                              style: kTextStyle.copyWith(color: kTitleColor),
                                            ),
                                          ),
                                          const SizedBox(height: 20.0),
                                          ButtonGlobalWithoutIcon(buttontext: 'Purchase Now', buttonDecoration: kButtonDecoration.copyWith(color: kBlueTextColor), onPressed: null, buttonTextColor: kWhiteTextColor),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20.0),
                                  Expanded(
                                    flex: 1,
                                    child: Stack(
                                      alignment: Alignment.topCenter,
                                      children: [
                                        Container(
                                          height: 550,
                                          padding: const EdgeInsets.all(10.0),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10.0),
                                            border: Border.all(
                                              color: const Color(0xFFFF4C3C),
                                            ),
                                            color: const Color(0xFFFF4C3C).withOpacity(0.1),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              const Spacer(),
                                              Container(
                                                height: 80,
                                                width: 80,
                                                decoration: const BoxDecoration(
                                                  image: DecorationImage(image: AssetImage('images/yearly.png'), fit: BoxFit.cover),
                                                ),
                                              ),
                                              Text(
                                                'Yearly',
                                                style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 10.0),
                                              Row(
                                                children: [
                                                  Text(
                                                    '\$ 1350',
                                                    style: kTextStyle.copyWith(color: const Color(0xFFFF4C3C), fontWeight: FontWeight.bold, fontSize: 21.0),
                                                  ),
                                                  const SizedBox(width: 4.0),
                                                  Text(
                                                    '\$ 1400',
                                                    style: kTextStyle.copyWith(color: kGreyTextColor, decoration: TextDecoration.lineThrough, fontSize: 10.0),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10.0),
                                              Text(
                                                'Our Premium Features',
                                                style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 10.0),
                                              ListTile(
                                                visualDensity: const VisualDensity(vertical: -4),
                                                contentPadding: EdgeInsets.zero,
                                                horizontalTitleGap: 5,
                                                leading: const Icon(
                                                  FeatherIcons.check,
                                                  color: Color(0xFFFF4C3C),
                                                ),
                                                title: Text(
                                                  'Free Lifetime Update',
                                                  style: kTextStyle.copyWith(color: kTitleColor),
                                                ),
                                              ),
                                              ListTile(
                                                visualDensity: const VisualDensity(vertical: -4),
                                                contentPadding: EdgeInsets.zero,
                                                horizontalTitleGap: 5,
                                                leading: const Icon(
                                                  FeatherIcons.check,
                                                  color: Color(0xFFFF4C3C),
                                                ),
                                                title: Text(
                                                  'Android & iOS App Support',
                                                  style: kTextStyle.copyWith(color: kTitleColor),
                                                ),
                                              ),
                                              ListTile(
                                                visualDensity: const VisualDensity(vertical: -4),
                                                contentPadding: EdgeInsets.zero,
                                                horizontalTitleGap: 5,
                                                leading: const Icon(
                                                  FeatherIcons.check,
                                                  color: Color(0xFFFF4C3C),
                                                ),
                                                title: Text(
                                                  'Premium Customer Support',
                                                  style: kTextStyle.copyWith(color: kTitleColor),
                                                ),
                                              ),
                                              ListTile(
                                                visualDensity: const VisualDensity(vertical: -4),
                                                contentPadding: EdgeInsets.zero,
                                                horizontalTitleGap: 5,
                                                leading: const Icon(
                                                  FeatherIcons.check,
                                                  color: Color(0xFFFF4C3C),
                                                ),
                                                title: Text(
                                                  'Custom Invoice Branding',
                                                  style: kTextStyle.copyWith(color: kTitleColor),
                                                ),
                                              ),
                                              ListTile(
                                                visualDensity: const VisualDensity(vertical: -4),
                                                contentPadding: EdgeInsets.zero,
                                                horizontalTitleGap: 5,
                                                leading: const Icon(
                                                  FeatherIcons.check,
                                                  color: Color(0xFFFF4C3C),
                                                ),
                                                title: Text(
                                                  'Unlimited Usage',
                                                  style: kTextStyle.copyWith(color: kTitleColor),
                                                ),
                                              ),
                                              ListTile(
                                                visualDensity: const VisualDensity(vertical: -4),
                                                contentPadding: EdgeInsets.zero,
                                                horizontalTitleGap: 5,
                                                leading: const Icon(
                                                  FeatherIcons.check,
                                                  color: Color(0xFFFF4C3C),
                                                ),
                                                title: Text(
                                                  'Free Data Backup',
                                                  style: kTextStyle.copyWith(color: kTitleColor),
                                                ),
                                              ),
                                              const SizedBox(height: 20.0),
                                              ButtonGlobalWithoutIcon(buttontext: 'Purchase Now', buttonDecoration: kButtonDecoration.copyWith(color: const Color(0xFFFF4C3C)), onPressed: null, buttonTextColor: kWhiteTextColor),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 20.0),
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      padding: const EdgeInsets.all(10.0),
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), border: Border.all(color: kBorderColorTextField)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Container(
                                            height: 80,
                                            width: 80,
                                            decoration: const BoxDecoration(
                                              image: DecorationImage(image: AssetImage('images/lifetime.png'), fit: BoxFit.cover),
                                            ),
                                          ),
                                          Text(
                                            'Lifetime',
                                            style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 10.0),
                                          Text(
                                            '\$ 850',
                                            style: kTextStyle.copyWith(color: const Color(0xFF8752EE), fontWeight: FontWeight.bold, fontSize: 21.0),
                                          ),
                                          const SizedBox(height: 10.0),
                                          Text(
                                            'Our Premium Features',
                                            style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 10.0),
                                          ListTile(
                                            visualDensity: const VisualDensity(vertical: -4),
                                            contentPadding: EdgeInsets.zero,
                                            horizontalTitleGap: 5,
                                            leading: const Icon(
                                              FeatherIcons.check,
                                              color: Color(0xFF8752EE),
                                            ),
                                            title: Text(
                                              'Free Lifetime Update',
                                              style: kTextStyle.copyWith(color: kTitleColor),
                                            ),
                                          ),
                                          ListTile(
                                            visualDensity: const VisualDensity(vertical: -4),
                                            contentPadding: EdgeInsets.zero,
                                            horizontalTitleGap: 5,
                                            leading: const Icon(
                                              FeatherIcons.check,
                                              color: Color(0xFF8752EE),
                                            ),
                                            title: Text(
                                              'Android & iOS App Support',
                                              style: kTextStyle.copyWith(color: kTitleColor),
                                            ),
                                          ),
                                          ListTile(
                                            visualDensity: const VisualDensity(vertical: -4),
                                            contentPadding: EdgeInsets.zero,
                                            horizontalTitleGap: 5,
                                            leading: const Icon(
                                              FeatherIcons.check,
                                              color: Color(0xFF8752EE),
                                            ),
                                            title: Text(
                                              'Premium Customer Support',
                                              style: kTextStyle.copyWith(color: kTitleColor),
                                            ),
                                          ),
                                          ListTile(
                                            visualDensity: const VisualDensity(vertical: -4),
                                            contentPadding: EdgeInsets.zero,
                                            horizontalTitleGap: 5,
                                            leading: const Icon(
                                              FeatherIcons.check,
                                              color: Color(0xFF8752EE),
                                            ),
                                            title: Text(
                                              'Custom Invoice Branding',
                                              style: kTextStyle.copyWith(color: kTitleColor),
                                            ),
                                          ),
                                          ListTile(
                                            visualDensity: const VisualDensity(vertical: -4),
                                            contentPadding: EdgeInsets.zero,
                                            horizontalTitleGap: 5,
                                            leading: const Icon(
                                              FeatherIcons.check,
                                              color: Color(0xFF8752EE),
                                            ),
                                            title: Text(
                                              'Unlimited Usage',
                                              style: kTextStyle.copyWith(color: kTitleColor),
                                            ),
                                          ),
                                          ListTile(
                                            visualDensity: const VisualDensity(vertical: -4),
                                            contentPadding: EdgeInsets.zero,
                                            horizontalTitleGap: 5,
                                            leading: const Icon(
                                              FeatherIcons.check,
                                              color: Color(0xFF8752EE),
                                            ),
                                            title: Text(
                                              'Free Data Backup',
                                              style: kTextStyle.copyWith(color: kTitleColor),
                                            ),
                                          ),
                                          const SizedBox(height: 20.0),
                                          ButtonGlobalWithoutIcon(buttontext: 'Purchase Now', buttonDecoration: kButtonDecoration.copyWith(color: const Color(0xFF8752EE)), onPressed: null, buttonTextColor: kWhiteTextColor),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        Positioned(
                          top: 55,
                          child: Container(
                            padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 5.0, bottom: 5.0),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(30.0), color: const Color(0xFFFF4C3C)),
                            child: Text(
                              'Save 65%',
                              style: kTextStyle.copyWith(color: kWhiteTextColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
