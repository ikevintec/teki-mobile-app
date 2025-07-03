import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/totalesFormaPagos.dart';
import 'package:teki_app/src/data/repositories/ticket_sale_repository_impl.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/list_comprobantes.dart';
import 'package:teki_app/src/providers/auth/login.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/contstants.dart';

final filtroDesdeProvider = StateProvider<DateTime?>((ref) => null);
final filtroHastaProvider = StateProvider<DateTime?>((ref) => null);

class VerComprobanteScreen extends ConsumerStatefulWidget {
  const VerComprobanteScreen({super.key});

  @override
  ConsumerState<VerComprobanteScreen> createState() =>
      _VerComprobanteScreenState();
}

class _VerComprobanteScreenState extends ConsumerState<VerComprobanteScreen> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _dateController2 = TextEditingController();
  final DateFormat _formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

  DateTime? _lastDesde;
  DateTime? _lastHasta;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    final desde = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final hasta = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    _dateController.text = _formatter.format(desde);
    _dateController2.text = _formatter.format(hasta);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(filtroDesdeProvider.notifier).state = desde;
      ref.read(filtroHastaProvider.notifier).state = hasta;
    });

    _lastDesde = desde;
    _lastHasta = hasta;
  }

  Future<void> _selectDate(
    TextEditingController controller,
    bool isStart,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ColorSchema.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final adjusted = isStart
          ? DateTime(picked.year, picked.month, picked.day, 0, 0, 0)
          : DateTime(picked.year, picked.month, picked.day, 23, 59, 59);

      setState(() {
        controller.text = _formatter.format(adjusted);
      });

      if (isStart) {
        ref.read(filtroDesdeProvider.notifier).state = adjusted;
      } else {
        ref.read(filtroHastaProvider.notifier).state = adjusted;
      }

      // Forzar refresco de totales si cambió alguna fecha
      if (isStart && adjusted != _lastDesde ||
          !isStart && adjusted != _lastHasta) {
        setState(() {
          if (isStart) _lastDesde = adjusted;
          if (!isStart) _lastHasta = adjusted;
        });
      }
    }
  }

  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hintText,
      hintStyle: GoogleFonts.nunito(fontSize: 14),
      prefixIcon: const Icon(Icons.calendar_month_rounded,
          size: 20, color: Colors.black),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildDatePickers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Desde",
                      style: GoogleFonts.raleway(
                          fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _dateController,
                    decoration: _buildInputDecoration("Fecha de inicio"),
                    style:
                        GoogleFonts.nunito(fontSize: 14, color: Colors.black),
                    readOnly: true,
                    onTap: () => _selectDate(_dateController, true),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Hasta",
                      style: GoogleFonts.raleway(
                          fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _dateController2,
                    decoration: _buildInputDecoration("Fecha de fin"),
                    style:
                        GoogleFonts.nunito(fontSize: 14, color: Colors.black),
                    readOnly: true,
                    onTap: () => _selectDate(_dateController2, false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<List<PaymentMethodTotal>> _fetchTotales() async {
    final desde = ref.watch(filtroDesdeProvider);
    final hasta = ref.watch(filtroHastaProvider);

    if (desde == null || hasta == null) return [];

    final filtroDesde = DateFormat('dd-MM-yyyy H:mm:ss').format(desde);
    final filtroHasta = DateFormat('dd-MM-yyyy H:mm:ss').format(hasta);

    final config = ref.read(sesionProvider);
    final ruc = config.companySelected?.ruc ?? '';
    final idPuntoVenta = config.office?.id ?? 0;
    final idVendedor = ref.read(authStateProvider).user?.id ?? 0;

    final repo = TicketSaleRepositoryImpl();

    return await repo.datasource.getTotalesPorFormaPago(
      filtroDesde: filtroDesde,
      filtroHasta: filtroHasta,
      filtroRucEmisor: ruc,
      idPuntoVenta: idPuntoVenta,
      idVendedor: idVendedor,
    );
  }

  Widget _buildTotalesSection() {
    return FutureBuilder<List<PaymentMethodTotal>>(
      future: _fetchTotales(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        String simbolo(String moneda) {
          switch (moneda) {
            case 'PEN':
              return 'S/';
            case 'USD':
              return '\$';
            case 'EUR':
              return '€';
            default:
              return '';
          }
        }

        return Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: items.map((item) {
              return RichText(
                text: TextSpan(
                  style: GoogleFonts.raleway(
                    fontSize: 15,
                    color: Colors.black,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Total:  ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                          '${simbolo(item.codigoMoneda)} ${item.monto.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Ver Comprobante',
            style: TextStyle(color: Colors.white)),
        backgroundColor: ColorSchema.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDatePickers(),
            const SizedBox(height: 16),
            _buildTotalesSection(),
            const SizedBox(height: 24),
            const Text("Comprobantes:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Expanded(child: TicketListSection()),
          ],
        ),
      ),
    );
  }
}
