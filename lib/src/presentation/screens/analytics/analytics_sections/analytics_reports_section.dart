import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/repositories/dashboard_repository_impl.dart';
import 'package:teki_app/src/presentation/widgets/loader/screen_loader.dart';
import 'package:teki_app/src/utils/notifications.dart';

class AnalyticsReportSection extends StatefulWidget {
  final int idPuntoVenta;

  const AnalyticsReportSection({super.key, required this.idPuntoVenta});

  @override
  State<AnalyticsReportSection> createState() => _AnalyticsReportSectionState();
}

class _AnalyticsReportSectionState extends State<AnalyticsReportSection> {
  int totalClientes = 0;
  int totalVentas = 0;
  bool loading = true;
  List<Map<String, dynamic>> montosPorMoneda = [];

  late final DashboardRepositoryImpl dashboardRepository;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    dashboardRepository = DashboardRepositoryImpl();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstLoad) {
      _isFirstLoad = false;
      _loadDashboardData();
    }
  }

  @override
  void didUpdateWidget(covariant AnalyticsReportSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.idPuntoVenta != widget.idPuntoVenta) {
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => loading = true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const ScreenLoader(message: 'Cargando información'),
      );

      try {
        final clienteResult = await dashboardRepository.getCustomerCount();
        totalClientes = clienteResult.total;
      } catch (e) {
        errorNotification("Error cargando clientes: $e");
      }

      try {
        final ventaResult =
            await dashboardRepository.getSalesCount(widget.idPuntoVenta);
        totalVentas = ventaResult.total;
      } catch (e) {
        errorNotification('Error cargando ventas concretadas');
      }

      try {
        final now = DateTime.now();
        final filtroDesde = DateTime(now.year, now.month, now.day, 0, 0, 0);
        final filtroHasta = DateTime(now.year, now.month, now.day, 23, 59, 59);
        final dateFormat = DateFormat('dd-MM-yyyy H:mm:ss');

        final formattedDesde = dateFormat.format(filtroDesde);
        final formattedHasta = dateFormat.format(filtroHasta);

        final resultMontos = await dashboardRepository.getAmountsByCurrency({
          'filtroEstadoAnulacion': 'false',
          'filtroDesde': formattedDesde,
          'filtroHasta': formattedHasta,
          'idPuntoVenta': widget.idPuntoVenta.toString(),
        });

        montosPorMoneda = resultMontos;
      } catch (e) {
        errorNotification("❌ Error al mostrar la Ventas del Día: ");
      }

      if (mounted) {
        Navigator.of(context).pop(); // cerrar loader
        setState(() => loading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double cardWidth = MediaQuery.of(context).size.width;
    const cardSpacing = 10.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Wrap(
            spacing: cardSpacing,
            runSpacing: cardSpacing,
            alignment: WrapAlignment.center,
            children: [
              buildReportCard(
                cardWidth,
                Colors.blue.shade50.withOpacity(0.6),
                "Ventas del Día",
                loading
                    ? "Cargando..."
                    : montosPorMoneda.map((e) {
                        final moneda = e["codigoMoneda"];
                        final monto = (e["monto"] ?? 0.0) as double;
                        String simbolo = switch (moneda) {
                          "PEN" => "S/",
                          "USD" => "\$",
                          "EUR" => "€",
                          _ => ""
                        };
                        return "$simbolo ${monto.toStringAsFixed(2)}";
                      }).join("\n"),
                "assets/icons/icon_image/sales.png",
                Colors.blue,
                Colors.blue.shade300,
                Colors.blue.shade50.withOpacity(0.6),
              ),
              buildReportCard(
                cardWidth,
                Colors.green.shade50.withOpacity(0.6),
                "Aperturar Caja",
                "20,000",
                "assets/icons/icon_image/purchase.png",
                Colors.green,
                Colors.green.shade300,
                Colors.green.shade50.withOpacity(0.6),
              ),
              buildReportCard(
                cardWidth,
                Colors.purple.shade50.withOpacity(0.6),
                "Ventas\nConcretadas",
                loading ? "Cargando..." : "$totalVentas",
                "assets/icons/icon_image/purchase_list.png",
                Colors.purple,
                Colors.purple.shade300,
                Colors.purple.shade50.withOpacity(0.6),
              ),
              buildReportCard(
                cardWidth,
                Colors.orange.shade50.withOpacity(0.6),
                "Clientes",
                loading ? "Cargando..." : "$totalClientes",
                "assets/icons/icon_image/customer.png",
                Colors.orange,
                Colors.orange.shade300,
                Colors.orange.shade50.withOpacity(0.6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildReportCard(
    double cardWidth,
    Color reportColor,
    String reportTitle,
    String balance,
    String reportIcon,
    Color reportIconColor,
    Color balanceColor,
    Color splashPressedColor,
  ) {
    return SizedBox(
      width: (cardWidth - 42) / 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        splashColor: splashPressedColor,
        onTap: () {},
        child: Card(
          color: reportColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white54,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: ImageIcon(
                      AssetImage(reportIcon),
                      color: reportIconColor,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reportTitle,
                        style: GoogleFonts.raleway(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF555555),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        balance,
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: balanceColor,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
