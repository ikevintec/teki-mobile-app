import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:teki_app/src/shared/services/printer/printer_service.dart';

/// Transporte BLE para impresoras térmicas ESC/POS (p. ej. Xprinter XP-P810).
/// No requiere emparejar la impresora desde los ajustes del sistema: se
/// conecta directo por GATT y escribe sobre el characteristic de impresión.
class BleEscPosPrinterService implements PrinterService {
  /// Pares service/characteristic conocidos de impresoras térmicas BLE,
  /// en orden de prioridad. Si ninguno está presente, se cae a heurística
  /// genérica (cualquier characteristic escribible de un servicio custom).
  static final List<(Guid, Guid)> _knownPrinterEndpoints = [
    // Xprinter y clones (XP-P810 confirmada físicamente)
    (Guid('e7810a71-73ae-499d-8c15-faa9aef0c3f2'), Guid('bef8d6c9-9c21-4c9e-b632-bd58c1009f9f')),
    // Perfil corto usado por muchas térmicas genéricas
    (Guid('18f0'), Guid('2af1')),
    // Módulos ISSC/Microchip (Goojprt, MTP-II y similares)
    (Guid('49535343-fe7d-4ae5-8fa9-9fafd205e455'), Guid('49535343-8841-43f4-a8d4-ecbe34729bb3')),
  ];

  /// Servicios GATT estándar que nunca son el endpoint de impresión.
  static final Set<Guid> _standardServices = {
    Guid('1800'), // Generic Access
    Guid('1801'), // Generic Attribute
    Guid('180a'), // Device Information
    Guid('180f'), // Battery
  };


  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeCharacteristic;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;

  final _scanController = StreamController<List<PrinterDevice>>.broadcast();
  StreamSubscription<List<ScanResult>>? _scanSub;

  @override
  Stream<List<PrinterDevice>> get scanResults => _scanController.stream;

  @override
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    await _ensureBluetoothOn();

    // FBP ya deduplica por remoteId dentro de scanResults; solo se filtran
    // los dispositivos sin nombre anunciado (las impresoras siempre lo traen).
    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      final devices = results
          .where((r) => r.advertisementData.advName.isNotEmpty || r.device.platformName.isNotEmpty)
          .map((r) => PrinterDevice(
                id: r.device.remoteId.str,
                name: r.advertisementData.advName.isNotEmpty
                    ? r.advertisementData.advName
                    : r.device.platformName,
                rssi: r.rssi,
              ))
          .toList();
      _scanController.add(devices);
      for (final r in results) {
        _log('BLE device discovered: ${r.device.remoteId.str} "${r.advertisementData.advName}" rssi=${r.rssi}');
      }
    });

    _log('BLE scan started (timeout ${timeout.inSeconds}s)');
    await FlutterBluePlus.startScan(timeout: timeout);
  }

  @override
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSub?.cancel();
    _scanSub = null;
    _log('BLE scan stopped');
  }

  @override
  Future<PrinterDevice> connect(PrinterDevice printer) async {
    await _ensureBluetoothOn();
    await disconnect();

    final device = BluetoothDevice.fromId(printer.id);
    _log('Connecting to ${printer.id} (${printer.name})');
    try {
      // mtu: 512 aplica solo en Android; iOS negocia su MTU automáticamente.
      await device.connect(timeout: const Duration(seconds: 15));
    } catch (e) {
      _log('Connect failed: $e');
      throw PrinterException('No se pudo conectar a ${printer.name}. Verifique que esté encendida y cerca.');
    }
    _log('Connected. Discovering services');

    final characteristic = await _findWriteCharacteristic(device, printer);
    _device = device;
    _writeCharacteristic = characteristic;
    _watchConnection(device);

    return printer.copyWith(
      serviceUuid: characteristic.serviceUuid.str128,
      characteristicUuid: characteristic.characteristicUuid.str128,
    );
  }

  @override
  Future<void> disconnect() async {
    await _connectionSub?.cancel();
    _connectionSub = null;
    final device = _device;
    _device = null;
    _writeCharacteristic = null;
    if (device != null) {
      try {
        await device.disconnect();
        _log('Disconnected from ${device.remoteId.str}');
      } catch (e) {
        _log('Disconnect error (ignored): $e');
      }
    }
  }

  @override
  Future<bool> isConnected() async =>
      _device != null && _device!.isConnected && _writeCharacteristic != null;

  @override
  Future<void> ensureConnected(PrinterDevice printer) async {
    if (await isConnected() && _device!.remoteId.str == printer.id) return;
    _log('Not connected, reconnecting to ${printer.id}');
    await connect(printer);
  }

  @override
  Future<void> printBytes(List<int> bytes) async {
    final characteristic = _writeCharacteristic;
    final device = _device;
    if (characteristic == null || device == null || !device.isConnected) {
      throw PrinterException('La impresora no está conectada.');
    }

    // Se prefiere Write CON respuesta: el ACK por chunk da backpressure real.
    // Write Without Response depende del callback "buffer listo" de la
    // plataforma, que en iOS no siempre llega con estas impresoras y deja el
    // write colgado hasta el timeout aunque los datos sí hayan salido.
    final withoutResponse = !characteristic.properties.write &&
        characteristic.properties.writeWithoutResponse;
    final chunkSize = _chunkSizeFor(device);
    final totalChunks = (bytes.length / chunkSize).ceil();
    _log('Sending ${bytes.length} bytes in $totalChunks chunks of $chunkSize (wwr=$withoutResponse)');

    try {
      for (var i = 0; i < bytes.length; i += chunkSize) {
        final end = (i + chunkSize > bytes.length) ? bytes.length : i + chunkSize;
        final chunk = bytes.sublist(i, end);
        await characteristic.write(chunk, withoutResponse: withoutResponse);
        _log('Chunk ${(i ~/ chunkSize) + 1}/$totalChunks');
        // Write Without Response no tiene ACK: un pequeño pacing evita
        // desbordar el buffer de la impresora en tickets grandes.
        if (withoutResponse) {
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }
    } catch (e) {
      _log('Write failed: $e');
      throw PrinterException('Falló el envío a la impresora. Reintente la impresión.');
    }
    _log('Print completed');
  }

  // ---------------------------------------------------------------------------

  /// Payload máximo por write: MTU negociado (mtuNow, lo reporta la librería
  /// en ambas plataformas) menos 3 bytes de cabecera ATT, acotado a 512.
  /// Fallback documentado: si el MTU quedó en el mínimo BLE (23, sin
  /// negociar), se usan 20 bytes por write — lento pero siempre válido.
  int _chunkSizeFor(BluetoothDevice device) {
    final mtu = device.mtuNow;
    if (mtu <= 23) return 20;
    return (mtu - 3).clamp(20, 512);
  }

  Future<BluetoothCharacteristic> _findWriteCharacteristic(
    BluetoothDevice device,
    PrinterDevice printer,
  ) async {
    List<BluetoothService> services;
    try {
      services = await device.discoverServices();
    } catch (e) {
      await device.disconnect();
      throw PrinterException('No se pudieron leer los servicios de la impresora.');
    }
    for (final s in services) {
      _log('Service discovered: ${s.serviceUuid.str128}');
    }

    // 1. Endpoint guardado de una conexión anterior (reconexión).
    if (printer.serviceUuid != null && printer.characteristicUuid != null) {
      final saved = _findByUuids(services, Guid(printer.serviceUuid!), Guid(printer.characteristicUuid!));
      if (saved != null && _isWritable(saved)) {
        _log('Writable characteristic found (saved): ${saved.characteristicUuid.str128} '
            '(write=${saved.properties.write}, wwr=${saved.properties.writeWithoutResponse})');
        return saved;
      }
    }

    // 2. Pares service/characteristic conocidos de impresoras.
    for (final (serviceUuid, charUuid) in _knownPrinterEndpoints) {
      final known = _findByUuids(services, serviceUuid, charUuid);
      if (known != null && _isWritable(known)) {
        _log('Writable characteristic found (known): ${known.characteristicUuid.str128}');
        return known;
      }
    }

    // 3. Heurística: characteristic escribible de servicios no estándar,
    //    prefiriendo Write Without Response (modo típico de impresión).
    final candidates = services
        .where((s) => !_standardServices.contains(s.serviceUuid))
        .expand((s) => s.characteristics)
        .where(_isWritable)
        .toList();
    if (candidates.isNotEmpty) {
      candidates.sort((a, b) {
        int score(BluetoothCharacteristic c) => c.properties.writeWithoutResponse ? 0 : 1;
        return score(a).compareTo(score(b));
      });
      final chosen = candidates.first;
      _log('Writable characteristic found (heuristic): ${chosen.characteristicUuid.str128}');
      return chosen;
    }

    await device.disconnect();
    throw PrinterException(
        'El dispositivo no expone un canal de impresión compatible (ESC/POS sobre BLE).');
  }

  BluetoothCharacteristic? _findByUuids(
    List<BluetoothService> services,
    Guid serviceUuid,
    Guid charUuid,
  ) {
    for (final s in services) {
      if (s.serviceUuid != serviceUuid) continue;
      for (final c in s.characteristics) {
        if (c.characteristicUuid == charUuid) return c;
      }
    }
    return null;
  }

  bool _isWritable(BluetoothCharacteristic c) =>
      c.properties.write || c.properties.writeWithoutResponse;

  void _watchConnection(BluetoothDevice device) {
    _connectionSub?.cancel();
    _connectionSub = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _log('Disconnected (event) ${device.remoteId.str}');
        // El characteristic deja de ser válido; la próxima impresión
        // pasará por ensureConnected() y volverá a descubrir servicios.
        _writeCharacteristic = null;
      }
    });
  }

  Future<void> _ensureBluetoothOn() async {
    if (await FlutterBluePlus.isSupported == false) {
      throw PrinterException('Este dispositivo no soporta Bluetooth LE.');
    }
    final state = await FlutterBluePlus.adapterState
        .firstWhere((s) => s != BluetoothAdapterState.unknown)
        .timeout(const Duration(seconds: 5), onTimeout: () => BluetoothAdapterState.unknown);
    if (state != BluetoothAdapterState.on) {
      throw PrinterException('Bluetooth está apagado. Enciéndalo para usar la impresora.');
    }
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[BlePrinter] $message');
  }

  void dispose() {
    _scanSub?.cancel();
    _connectionSub?.cancel();
    _scanController.close();
  }
}
