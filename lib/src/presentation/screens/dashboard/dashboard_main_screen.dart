import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:teki_app/main.dart';
// import 'package:teki_app/src/presentation/screens/dashboard/dashboard_sections/carousel_section.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_sections/header_section.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_sections/services_section.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_sections/today_reports_section.dart';
import 'package:teki_app/src/presentation/widgets/drawer/dashboard_drawer.dart';
import 'package:teki_app/src/providers/config/config.dart';

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
      body: Stack(
        children: [
          // Fondo y servicios
          Container(
            color: const Color(0xFFF8FAFC),
            child: Column(
              children: [
                // Espacio para el header
                const SizedBox(height: 400),
                // Sección de servicios con scroll interno
                const Expanded(
                  child: ServicesSection(showNavigationBar: true),
                ),
              ],
            ),
          ),
          // Header
          if (isSmallScreen)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 190,
                child: DashboardHeaderSection(
                  openDrawer: () {
                    if (!Platform.isAndroid && !Platform.isIOS) {
                      controller.setExtended(true);
                    }
                    _key.currentState?.openDrawer();
                  },
                ),
              ),
            ),
          // Sección de reportes - por encima de todo
          Positioned(
            top:165, // Posición para que se superponga al header
            left: 0,
            right: 0,
            child: TodayReportsSection(key: todayReportKey, idPuntoVenta: id ?? 0),
          ),
        ],
      ),
    );
  }
}
