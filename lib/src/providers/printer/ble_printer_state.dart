import 'package:teki_app/src/shared/services/printer/printer_service.dart';

class BlePrinterState {
  final PrinterStatus status;
  final List<PrinterDevice> devices;
  final PrinterDevice? savedPrinter;
  final String? error;

  const BlePrinterState({
    this.status = PrinterStatus.idle,
    this.devices = const [],
    this.savedPrinter,
    this.error,
  });

  bool get hasPrinter => savedPrinter != null;
  bool get isBusy =>
      status == PrinterStatus.scanning ||
      status == PrinterStatus.connecting ||
      status == PrinterStatus.printing;

  BlePrinterState copyWith({
    PrinterStatus? status,
    List<PrinterDevice>? devices,
    PrinterDevice? savedPrinter,
    bool clearSavedPrinter = false,
    String? error,
    bool clearError = false,
  }) =>
      BlePrinterState(
        status: status ?? this.status,
        devices: devices ?? this.devices,
        savedPrinter: clearSavedPrinter ? null : (savedPrinter ?? this.savedPrinter),
        error: clearError ? null : (error ?? this.error),
      );
}
