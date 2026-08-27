import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/esc_pos/esc_pos_order.dart';
import 'package:teki_app/src/providers/printer/ble_printer_state.dart';
import 'package:teki_app/src/shared/services/key_value_storage.dart';
import 'package:teki_app/src/shared/services/key_values_storage_impl.dart';
import 'package:teki_app/src/shared/services/printer/ble_esc_pos_printer_service.dart';
import 'package:teki_app/src/shared/services/printer/esc_pos_generator_service.dart';
import 'package:teki_app/src/shared/services/printer/printer_service.dart';
import 'package:teki_app/src/utils/storage_keys.dart';

/// Transporte de impresión de tickets del dispositivo. Hoy la única
/// implementación es BLE; otras (red, USB) se registran aquí sin tocar la UI.
final printerServiceProvider = Provider<PrinterService>((ref) {
  final service = BleEscPosPrinterService();
  ref.onDispose(service.dispose);
  return service;
});

final blePrinterProvider =
    StateNotifierProvider<BlePrinterNotifier, BlePrinterState>((ref) {
  return BlePrinterNotifier(
    printerService: ref.watch(printerServiceProvider),
    storage: KeyValueStorageServiceImpl(),
  );
});

class BlePrinterNotifier extends StateNotifier<BlePrinterState> {
  final PrinterService printerService;
  final KeyValueStorageService storage;
  final EscPosGeneratorService _generator = EscPosGeneratorService();

  StreamSubscription<List<PrinterDevice>>? _scanSub;
  Timer? _scanTimeout;

  BlePrinterNotifier({required this.printerService, required this.storage})
      : super(const BlePrinterState()) {
    _loadSavedPrinter();
  }

  Future<void> _loadSavedPrinter() async {
    final raw = await storage.getValue<String>(StorageKeys.blePrinter);
    final saved = PrinterDevice.decode(raw);
    if (saved != null && mounted) {
      state = state.copyWith(savedPrinter: saved, status: PrinterStatus.disconnected);
    }
  }

  Future<void> scan() async {
    if (state.isBusy) return;
    state = state.copyWith(status: PrinterStatus.scanning, devices: [], clearError: true);
    try {
      _scanSub?.cancel();
      _scanSub = printerService.scanResults.listen((devices) {
        if (mounted) state = state.copyWith(devices: devices);
      });
      const timeout = Duration(seconds: 10);
      await printerService.startScan(timeout: timeout);
      // startScan de flutter_blue_plus retorna al iniciar; el fin del escaneo
      // llega por timeout, así que el estado se libera con el mismo plazo.
      _scanTimeout?.cancel();
      _scanTimeout = Timer(timeout + const Duration(milliseconds: 300), () {
        if (mounted && state.status == PrinterStatus.scanning) {
          state = state.copyWith(status: PrinterStatus.idle);
        }
      });
    } on PrinterException catch (e) {
      if (mounted) state = state.copyWith(status: PrinterStatus.error, error: e.message);
    } catch (_) {
      if (mounted) {
        state = state.copyWith(status: PrinterStatus.error, error: 'No se pudo iniciar la búsqueda Bluetooth.');
      }
    }
  }

  Future<void> stopScan() async {
    _scanTimeout?.cancel();
    await printerService.stopScan();
    if (mounted && state.status == PrinterStatus.scanning) {
      state = state.copyWith(status: PrinterStatus.idle);
    }
  }

  /// Conecta la impresora elegida, resuelve su characteristic de escritura
  /// y la persiste como impresora del dispositivo. Se permite invocar
  /// durante un escaneo (lo detiene primero); no durante conexión/impresión.
  Future<void> select(PrinterDevice device) async {
    if (state.status == PrinterStatus.connecting || state.status == PrinterStatus.printing) {
      return;
    }
    await stopScan();
    state = state.copyWith(status: PrinterStatus.connecting, clearError: true);
    try {
      final connected = await printerService.connect(device);
      await storage.setKeyValue<String>(StorageKeys.blePrinter, connected.encode());
      if (mounted) {
        state = state.copyWith(status: PrinterStatus.connected, savedPrinter: connected);
      }
    } on PrinterException catch (e) {
      if (mounted) state = state.copyWith(status: PrinterStatus.error, error: e.message);
    }
  }

  Future<void> disconnect() async {
    await printerService.disconnect();
    if (mounted) state = state.copyWith(status: PrinterStatus.disconnected);
  }

  /// Olvida la impresora guardada (además de desconectarla).
  Future<void> forget() async {
    await printerService.disconnect();
    await storage.removeKey(StorageKeys.blePrinter);
    if (mounted) {
      state = state.copyWith(status: PrinterStatus.idle, clearSavedPrinter: true, devices: []);
    }
  }

  Future<void> setPaperWidth(int paperWidthMm) async {
    final saved = state.savedPrinter;
    if (saved == null) return;
    final updated = saved.copyWith(paperWidthMm: paperWidthMm);
    await storage.setKeyValue<String>(StorageKeys.blePrinter, updated.encode());
    if (mounted) state = state.copyWith(savedPrinter: updated);
  }

  /// Imprime el ticket de diagnóstico. Devuelve null si todo salió bien,
  /// o el mensaje de error para mostrar al usuario.
  Future<String?> printTest() async {
    final result = await _print(() async {
      final bytes = await _generator.buildTestTicket(
        paperWidthMm: state.savedPrinter?.paperWidthMm ?? 80,
      );
      await printerService.printBytes(bytes);
    });
    return result;
  }

  /// Imprime órdenes ESC/POS (mismo modelo que Coffe) en la impresora BLE.
  Future<String?> printOrders(List<EscPosOrder> orders) async {
    return _print(() async {
      final bytes = await _generator.buildFromOrders(
        orders,
        paperWidthMm: state.savedPrinter?.paperWidthMm ?? 80,
      );
      await printerService.printBytes(bytes);
    });
  }

  /// Envoltura común: reconexión + estado printing + bloqueo de dobles taps.
  Future<String?> _print(Future<void> Function() job) async {
    final printer = state.savedPrinter;
    if (printer == null) return 'No hay una impresora Bluetooth configurada.';
    if (state.isBusy) return null; // ya hay una impresión/conexión en curso

    state = state.copyWith(status: PrinterStatus.printing, clearError: true);
    try {
      await printerService.ensureConnected(printer);
      await job();
      if (mounted) state = state.copyWith(status: PrinterStatus.connected);
      return null;
    } on PrinterException catch (e) {
      if (mounted) state = state.copyWith(status: PrinterStatus.error, error: e.message);
      return e.message;
    } catch (_) {
      const message = 'Ocurrió un error al imprimir. Reintente.';
      if (mounted) state = state.copyWith(status: PrinterStatus.error, error: message);
      return message;
    }
  }

  /// Refresca el estado de conexión real (p. ej. al entrar a la pantalla).
  Future<void> refreshConnection() async {
    if (state.savedPrinter == null || state.isBusy) return;
    final connected = await printerService.isConnected();
    if (mounted) {
      state = state.copyWith(
        status: connected ? PrinterStatus.connected : PrinterStatus.disconnected,
      );
    }
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _scanTimeout?.cancel();
    super.dispose();
  }
}
