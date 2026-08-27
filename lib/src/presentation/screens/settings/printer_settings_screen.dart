import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/providers/printer/ble_printer.dart';
import 'package:teki_app/src/providers/printer/ble_printer_state.dart';
import 'package:teki_app/src/shared/services/printer/printer_service.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/notifications.dart';

/// Configuración → Impresoras: alta, prueba y estado de la impresora
/// térmica Bluetooth BLE del dispositivo.
class PrinterSettingsScreen extends ConsumerStatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  ConsumerState<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends ConsumerState<PrinterSettingsScreen> {
  bool _changingPrinter = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(blePrinterProvider.notifier).refreshConnection();
    });
  }

  @override
  void deactivate() {
    // No dejar el scan BLE activo al salir de la pantalla.
    ref.read(blePrinterProvider.notifier).stopScan();
    super.deactivate();
  }

  Future<void> _printTest() async {
    final error = await ref.read(blePrinterProvider.notifier).printTest();
    if (!mounted) return;
    if (error == null) {
      successNotification('Prueba enviada a la impresora.');
    } else {
      errorNotification(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(blePrinterProvider);

    ref.listen<BlePrinterState>(blePrinterProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        errorNotification(next.error!);
      }
      // Al conectar una impresora nueva se cierra el modo "cambiar".
      if (next.status == PrinterStatus.connected &&
          prev?.status == PrinterStatus.connecting &&
          _changingPrinter) {
        setState(() => _changingPrinter = false);
      }
    });

    final showScanner = !state.hasPrinter || _changingPrinter;

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(navigateName: 'Impresoras'),
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        color: const Color.fromARGB(255, 222, 242, 255).withValues(alpha: 0.4),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Impresora de tickets',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              if (state.hasPrinter) _buildSavedPrinterCard(state),
              if (showScanner) ...[
                if (state.hasPrinter) const SizedBox(height: 20),
                _buildScannerSection(state),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Impresora configurada ───────────────────────────────────────────────

  Widget _buildSavedPrinterCard(BlePrinterState state) {
    final printer = state.savedPrinter!;
    final notifier = ref.read(blePrinterProvider.notifier);
    final busy = state.isBusy;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ColorSchema.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.print_rounded, color: ColorSchema.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      printer.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bluetooth BLE · ${printer.id}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _statusChip(state.status),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('Ancho de papel:', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              const SizedBox(width: 10),
              ChoiceChip(
                label: const Text('80 mm'),
                selected: printer.paperWidthMm == 80,
                onSelected: busy ? null : (_) => notifier.setPaperWidth(80),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('58 mm'),
                selected: printer.paperWidthMm == 58,
                onSelected: busy ? null : (_) => notifier.setPaperWidth(58),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: busy ? null : _printTest,
              icon: state.status == PrinterStatus.printing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.receipt_long_rounded, size: 18),
              label: const Text('Imprimir prueba'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorSchema.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy
                      ? null
                      : () {
                          setState(() => _changingPrinter = true);
                          ref.read(blePrinterProvider.notifier).scan();
                        },
                  style: _outlinedStyle(),
                  child: const Text('Cambiar impresora', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: busy || state.status != PrinterStatus.connected
                      ? null
                      : () => ref.read(blePrinterProvider.notifier).disconnect(),
                  style: _outlinedStyle(),
                  child: const Text('Desconectar', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
          Center(
            child: TextButton(
              onPressed: busy ? null : () => ref.read(blePrinterProvider.notifier).forget(),
              child: Text(
                'Quitar impresora',
                style: TextStyle(fontSize: 12, color: Colors.red.shade400),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Escaneo y selección ─────────────────────────────────────────────────

  Widget _buildScannerSection(BlePrinterState state) {
    final scanning = state.status == PrinterStatus.scanning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: state.isBusy ? null : () => ref.read(blePrinterProvider.notifier).scan(),
            icon: scanning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.bluetooth_searching_rounded, size: 18),
            label: Text(scanning ? 'Buscando impresoras...' : 'Buscar impresoras'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorSchema.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (state.devices.isNotEmpty) ...[
          Text(
            'Dispositivos encontrados',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          ...state.devices.map((d) => _buildDeviceTile(d, state)),
        ] else if (!scanning) ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Encienda la impresora y presione "Buscar impresoras".',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDeviceTile(PrinterDevice device, BlePrinterState state) {
    final connecting = state.status == PrinterStatus.connecting;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _card(
        child: Row(
          children: [
            Icon(Icons.print_outlined, color: Colors.grey.shade700, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(device.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    'Bluetooth BLE · Señal: ${device.rssi ?? '--'} dBm',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  Text(
                    device.id,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: connecting
                  ? null
                  : () => ref.read(blePrinterProvider.notifier).select(device),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorSchema.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text(connecting ? '...' : 'Conectar', style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers de estilo ───────────────────────────────────────────────────

  Widget _statusChip(PrinterStatus status) {
    late final Color color;
    late final String label;
    late final IconData icon;
    switch (status) {
      case PrinterStatus.connected:
        color = Colors.green.shade600;
        label = 'Conectada';
        icon = Icons.check_circle_rounded;
        break;
      case PrinterStatus.printing:
        color = ColorSchema.primaryColor;
        label = 'Imprimiendo';
        icon = Icons.print_rounded;
        break;
      case PrinterStatus.connecting:
        color = Colors.orange.shade700;
        label = 'Conectando';
        icon = Icons.bluetooth_searching_rounded;
        break;
      default:
        color = Colors.grey.shade500;
        label = 'Desconectada';
        icon = Icons.bluetooth_disabled_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  ButtonStyle _outlinedStyle() => OutlinedButton.styleFrom(
        foregroundColor: Colors.grey.shade700,
        side: BorderSide(color: Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1)),
          ],
        ),
        child: child,
      );
}
