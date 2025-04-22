import 'dart:io';

import 'package:flutter/material.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_sections/carousel_section.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_sections/header_section.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_sections/services_section.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_sections/today_reports_section.dart';
import 'package:teki_app/src/presentation/widgets/drawer/dashboard_drawer.dart';
import 'package:sidebarx/sidebarx.dart';

class DashboardMainScreen extends StatefulWidget {
  const DashboardMainScreen({super.key});

  @override
  State<DashboardMainScreen> createState() => _DashboardMainScreenState();
}

class _DashboardMainScreenState extends State<DashboardMainScreen> {
  final controller = SidebarXController(selectedIndex: 0, extended: true);
  final _key = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      key: _key,
      drawer: DashboardDrawer(routeName: "Dashboard", controller: controller),
      body: Container(
        color: Colors.white70,
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            TodayReportsSection(),
            ServicesSection(),
            CarouselSection(),
          ],
        ),
      ),
      appBar: isSmallScreen
          ? PreferredSize(
              preferredSize: const Size.fromHeight(90),
              child: DashboardHeaderSection(
                openDrawer: () {
                  if (!Platform.isAndroid && !Platform.isIOS) {
                    controller.setExtended(true);
                  }
                  _key.currentState?.openDrawer();
                },
              ),
            )
          : null,
    );
  }
}
