import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:teki_app/main.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_sections/carousel_section.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_sections/header_section.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_sections/services_section.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_sections/today_reports_section.dart';
import 'package:teki_app/src/presentation/widgets/drawer/dashboard_drawer.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/presentation/widgets/loader/screen_loader.dart';

import 'package:teki_app/src/application.dart'; // Asegúrate de importar donde declaraste `routeObserver`

class DashboardMainScreen extends ConsumerStatefulWidget {
  const DashboardMainScreen({super.key});

  @override
  ConsumerState<DashboardMainScreen> createState() =>
      _DashboardMainScreenState();
}

class _DashboardMainScreenState extends ConsumerState<DashboardMainScreen>
    with RouteAware {
  final controller = SidebarXController(selectedIndex: 0, extended: true);
  final _key = GlobalKey<ScaffoldState>();
  Key todayReportKey = UniqueKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Se llama al regresar a esta pantalla
    setState(() {
      todayReportKey = UniqueKey(); // Fuerza reconstrucción
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(sesionProvider);
    final id = config.office?.id;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      key: _key,
      drawer: DashboardDrawer(routeName: "Dashboard", controller: controller),
      body: Container(
        color: Colors.white70,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            TodayReportsSection(key: todayReportKey, idPuntoVenta: id ?? 0),
            const ServicesSection(),
            const CarouselSection(),
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
