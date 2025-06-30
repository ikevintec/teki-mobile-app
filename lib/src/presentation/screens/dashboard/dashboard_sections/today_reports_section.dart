import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/data/repositories/dashboard_repository_impl.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/notifications.dart';
import 'package:teki_app/src/presentation/widgets/loader/screen_loader.dart';

class TodayReportsSection extends StatefulWidget {
  final int idPuntoVenta;
  const TodayReportsSection({super.key, required this.idPuntoVenta});

  @override
  State<TodayReportsSection> createState() => _TodayReportsSectionState();
}

class _TodayReportsSectionState extends State<TodayReportsSection> {
  final DashboardRepositoryImpl dashboardRepository = DashboardRepositoryImpl();

  int? totalClientes;
  int? totalVentas;
  List<Map<String, dynamic>>? montosPorMoneda;

  bool loadingClientes = true;
  bool loadingVentas = true;
  bool loadingMontos = true;

  @override
  void initState() {
    super.initState();
    _loadDataPartial();
  }

  Future<void> _loadDataPartial() async {
    final now = DateTime.now();
    final filtroDesde = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final filtroHasta = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final dateFormat = DateFormat('dd-MM-yyyy H:mm:ss');

    dashboardRepository.getCustomerCount().then((clienteResult) {
      setState(() {
        totalClientes = clienteResult.total;
        loadingClientes = false;
      });
    }).catchError((_) {
      errorNotification("Error cargando clientes");
      setState(() => loadingClientes = false);
    });

    dashboardRepository.getSalesCount(widget.idPuntoVenta).then((ventaResult) {
      setState(() {
        totalVentas = ventaResult.total;
        loadingVentas = false;
      });
    }).catchError((_) {
      // errorNotification("Error cargando ventas");
      setState(() => loadingVentas = false);
    });

    dashboardRepository.getAmountsByCurrency({
      'filtroEstadoAnulacion': 'false',
      'filtroDesde': dateFormat.format(filtroDesde),
      'filtroHasta': dateFormat.format(filtroHasta),
      'idPuntoVenta': widget.idPuntoVenta.toString(),
    }).then((resultMontos) {
      setState(() {
        montosPorMoneda = resultMontos;
        loadingMontos = false;
      });
    }).catchError((_) {
      errorNotification("❌ Error al mostrar las Ventas del Día");
      setState(() => loadingMontos = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final allLoading = loadingClientes && loadingVentas && loadingMontos;

    if (allLoading) {
      return const SizedBox(
        height: 640, // o el valor que se ajuste a tu UI
        child: Center(
          child: ScreenLoader(message: 'Cargando información...'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      margin: const EdgeInsets.only(left: 16, right: 16, top: 30),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(1, 5),
          ),
        ],
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade100,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Reportes diario",
                  style: GoogleFonts.raleway(
                    textStyle: TextStyle(
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.toNamed(AppRoutes.analytics),
                  icon: const Icon(Icons.arrow_forward_ios),
                  iconSize: 15,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildReports(
                  "Ventas",
                  montosPorMoneda != null
                      ? montosPorMoneda!.map((m) {
                          final moneda = m['codigoMoneda'];
                          final monto = (m['monto'] ?? 0).toStringAsFixed(2);
                          switch (moneda) {
                            case 'PEN':
                              return 'S/. $monto';
                            case 'USD':
                              return '\$ $monto';
                            case 'EUR':
                              return '€ $monto';
                            default:
                              return '$moneda $monto';
                          }
                        }).join('\n')
                      : '0',
                  Colors.white,
                  "assets/icons/icon_svg/sale_service_icon.svg",
                  screenWidth,
                  showCurrencySymbol: false,
                ),
                buildReports(
                  "Ventas Concretadas",
                  totalVentas != null ? "$totalVentas" : '0',
                  Colors.white,
                  "assets/icons/icon_svg/purchase_service_icon.svg",
                  screenWidth,
                  showCurrencySymbol: false,
                ),
                buildReports(
                  "Clientes",
                  totalClientes != null ? "$totalClientes" : '0',
                  Colors.white,
                  "assets/icons/icon_svg/expenses_icon.svg",
                  screenWidth,
                  showCurrencySymbol: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  GestureDetector buildReports(
    String title,
    String amount,
    Color reportColor,
    String reportIcon,
    double screenWidth, {
    bool showCurrencySymbol = true,
  }) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.analytics),
      child: Container(
        width: screenWidth * 0.27,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: reportColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white54,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SvgPicture.asset(
                  reportIcon,
                  color: ColorSchema.primaryColor,
                  width: 30,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                textStyle: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
            Text.rich(
              TextSpan(
                style: GoogleFonts.nunito(
                  textStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: screenWidth * 0.035,
                    color: const Color(0xFF333333),
                  ),
                ),
                children: [
                  if (showCurrencySymbol) const TextSpan(text: "\$"),
                  TextSpan(text: amount),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
