import 'dart:convert';

/// Estados del ciclo de vida de una impresora de tickets.
enum PrinterStatus {
  idle,
  scanning,
  connecting,
  connected,
  printing,
  disconnected,
  error,
}

class PrinterException implements Exception {
  final String message;
  PrinterException(this.message);

  @override
  String toString() => message;
}

/// Impresora de tickets vista desde la app, independiente del transporte.
/// Para BLE, [id] es el remoteId de flutter_blue_plus: en Android es la MAC
/// del periférico y en iOS un UUID que ese teléfono le asigna al dispositivo
/// (no es portable entre teléfonos ni plataformas).
class PrinterDevice {
  final String id;
  final String name;
  final String connectionType;
  final String? serviceUuid;
  final String? characteristicUuid;

  /// Ancho de papel en mm (58 u 80); define el layout del ticket ESC/POS.
  final int paperWidthMm;
  final int? rssi;

  const PrinterDevice({
    required this.id,
    required this.name,
    this.connectionType = 'BLE',
    this.serviceUuid,
    this.characteristicUuid,
    this.paperWidthMm = 80,
    this.rssi,
  });

  PrinterDevice copyWith({
    String? serviceUuid,
    String? characteristicUuid,
    int? paperWidthMm,
    int? rssi,
  }) =>
      PrinterDevice(
        id: id,
        name: name,
        connectionType: connectionType,
        serviceUuid: serviceUuid ?? this.serviceUuid,
        characteristicUuid: characteristicUuid ?? this.characteristicUuid,
        paperWidthMm: paperWidthMm ?? this.paperWidthMm,
        rssi: rssi ?? this.rssi,
      );

  Map<String, dynamic> toJson() => {
        'printerRemoteId': id,
        'printerName': name,
        'connectionType': connectionType,
        if (serviceUuid != null) 'serviceUuid': serviceUuid,
        if (characteristicUuid != null) 'characteristicUuid': characteristicUuid,
        'paperWidthMm': paperWidthMm,
      };

  factory PrinterDevice.fromJson(Map<String, dynamic> json) => PrinterDevice(
        id: json['printerRemoteId'],
        name: json['printerName'] ?? 'Impresora',
        connectionType: json['connectionType'] ?? 'BLE',
        serviceUuid: json['serviceUuid'],
        characteristicUuid: json['characteristicUuid'],
        paperWidthMm: json['paperWidthMm'] ?? 80,
      );

  String encode() => jsonEncode(toJson());

  static PrinterDevice? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return PrinterDevice.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

/// Transporte de impresión de tickets. La generación ESC/POS vive aparte
/// (EscPosGeneratorService), de modo que el mismo ticket pueda enviarse por
/// BLE hoy y por red/USB mañana con otra implementación de esta interfaz.
abstract class PrinterService {
  /// Dispositivos encontrados durante el escaneo (sin duplicados).
  Stream<List<PrinterDevice>> get scanResults;

  /// Inicia un escaneo acotado; se detiene solo al vencer [timeout].
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)});

  Future<void> stopScan();

  /// Conecta y descubre el characteristic de escritura. Devuelve el mismo
  /// dispositivo enriquecido con serviceUuid/characteristicUuid resueltos.
  Future<PrinterDevice> connect(PrinterDevice printer);

  Future<void> disconnect();

  Future<bool> isConnected();

  /// Garantiza una conexión lista para escribir; reconecta si hace falta.
  Future<void> ensureConnected(PrinterDevice printer);

  /// Envía bytes ESC/POS ya generados, fragmentando según el MTU real.
  Future<void> printBytes(List<int> bytes);
}
