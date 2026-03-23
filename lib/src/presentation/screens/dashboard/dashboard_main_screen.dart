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
    final screenHeight = MediaQuery.of(context).size.height;

    // Posición fija del card de TodayReports (solapado con el header)
    const double todayReportTop = 125.0;
    // Altura estimada del card de TodayReports
    const double todayReportCardHeight = 205.0;
    // La sección blanca comienza al 34% de la pantalla (se adapta a distintas alturas)
    final double whiteSectionTop = screenHeight * 0.32;
    // El padding superior del ServicesSection asegura que el grid empiece
    // debajo del card de TodayReports, sin importar el tamaño de pantalla
    final double servicesTopPadding = (todayReportTop + todayReportCardHeight - whiteSectionTop + 10)
        .clamp(20.0, 130.0);

    return Scaffold(
      key: _key,
      drawer: DashboardDrawer(routeName: "Dashboard", controller: controller),
      body: Stack(
        children: [
          // Fondo y servicios
          Column(
            children: [
              // Bloque superior con degradado
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color.fromARGB(255, 19, 94, 232),
                        Colors.blue[400]!,
                      ],
                    ),
                  ),
                ),
              ),
              // Bloque inferior blanco
              const SizedBox(height: 250),
            ],
          ),
          // Fondo blanco para ServicesSection
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            top: whiteSectionTop,
            child: Container(
              padding: EdgeInsets.only(top: Platform.isIOS ? 0 :servicesTopPadding),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
              ),
              child: const ServicesSection(showNavigationBar: true),
            ),
          ),
          // Header
          if (isSmallScreen)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 150,
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
            top: todayReportTop,
            left: 0,
            right: 0,
            child: TodayReportsSection(key: todayReportKey, idPuntoVenta: id ?? 0),
          ),
        ],
      ),
    );
  }
}
