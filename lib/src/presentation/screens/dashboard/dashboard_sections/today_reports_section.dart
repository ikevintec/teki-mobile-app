import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/data/repositories/dashboard_repository_impl.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/contstants.dart';

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
    }).catchError((error) {
      printError(info: "❌ Error al cargar clientes: ${error.toString()}");
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
      printError(info: "❌ Error al mostrar las Ventas del Día: $_");
      setState(() => loadingMontos = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
        padding: const EdgeInsets.only(right: 16, left: 16, top: 20, bottom: 35),
        margin: const EdgeInsets.only(left: 16, right: 16, top: 0),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color.fromARGB(255, 15, 78, 193),
            Colors.blue[400]!,
          ],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Reportes Diario",
                  style: GoogleFonts.raleway(
                    textStyle: TextStyle(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: () => Get.toNamed(AppRoutes.analytics),
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                    iconSize: 16,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
                buildReports(
                  "Ventas",
                  loadingMontos
                      ? "---"
                      : montosPorMoneda != null
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
                          : '---',
                  Colors.white,
                  "assets/icons/icon_svg/sale_service_icon.svg",
                  screenWidth,
                  showCurrencySymbol: false,
                ),
                buildReports(
                  "Ventas Concretadas",
                  loadingVentas
                      ? "---"
                      : totalVentas != null
                          ? "$totalVentas"
                          : '---',
                  Colors.white,
                  "assets/icons/icon_svg/purchase_service_icon.svg",
                  screenWidth,
                  showCurrencySymbol: false,
                ),
                buildReports(
                  "Clientes",
                  loadingClientes
                      ? "---"
                      : totalClientes != null
                          ? "$totalClientes"
                          : '---',
                  Colors.white,
                  "assets/icons/icon_svg/expenses_icon.svg",
                  screenWidth,
                  showCurrencySymbol: false,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Container buildReports(
    String title,
    String amount,
    Color reportColor,
    String reportIcon,
    double screenWidth, {
    bool showCurrencySymbol = true,
  }) {
    return Container(
        width: screenWidth * 0.27,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: reportColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: ColorSchema.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: ColorSchema.primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: SvgPicture.asset(
                  reportIcon,
                  colorFilter: ColorFilter.mode(
                    ColorSchema.primaryColor,
                    BlendMode.srcIn,
                  ),
                  width: 24,
                  height: 24,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                textStyle: TextStyle(
                  fontSize: screenWidth * 0.032,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF555555),
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                style: GoogleFonts.nunito(
                  textStyle: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: screenWidth * 0.03,
                    color: const Color(0xFF1F1F1F),
                    height: 1.1,
                  ),
                ),
                children: [
                  if (showCurrencySymbol) const TextSpan(text: "\$"),
                  TextSpan(text: amount),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
  }
}
