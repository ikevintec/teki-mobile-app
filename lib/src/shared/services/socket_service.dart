import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:teki_app/src/shared/services/token_storage.dart';
import 'package:teki_app/src/utils/constants.dart';

enum SocketEvent {
  commandRestaurant('commandRestaurant'),
  orderRestaurant('orderRestaurant');

  const SocketEvent(this.value);
  final String value;
}

class SocketService {
  SocketService._internal();
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  io.Socket? _socket;
  int _connectionCount = 0;
  String? _currentOfficeCode;

  final Map<SocketEvent, StreamController<dynamic>> _controllers = {
    for (final e in SocketEvent.values) e: StreamController<dynamic>.broadcast(),
  };

  final Map<String, List<void Function(dynamic)>> _listeners = {};

  /// Se incrementa en cada apertura/cierre: una apertura que terminó de leer
  /// el token después de otra más reciente (o de un cierre) se descarta.
  int _generation = 0;

  bool get isConnected => _socket?.connected ?? false;

  /// Conectado o en proceso de conexión/reconexión. Evita reabrir un socket
  /// que todavía está en handshake.
  bool get _isAlive => _socket?.active ?? false;

  Future<void> connect({required String officeCode}) async {
    _connectionCount++;
    if (_isAlive && _currentOfficeCode == officeCode) return;
    await _openSocket(officeCode);
  }

  /// Re-vincula el socket a otra sucursal sin alterar el conteo de leases:
  /// cierra la conexión anterior y abre una sola contra la nueva.
  Future<void> reconnectOffice(String officeCode) async {
    if (_connectionCount <= 0) return;
    if (_isAlive && _currentOfficeCode == officeCode) return;
    await _openSocket(officeCode);
  }

  Future<void> _openSocket(String officeCode) async {
    final generation = ++_generation;
    final token = await TokenStorage.getToken() ?? '';
    if (generation != _generation) return;

    _teardownSocket();
    _currentOfficeCode = officeCode;

    _socket = io.io(
      Environment.wsUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setPath(Environment.wsPath)
          .setQuery({
            'auth_token': token,
            'officeCode': officeCode,
            'clientType': 'WEB',
          })
          .setTimeout(4000)
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) => debugPrint('[Socket] Conectado a ${Environment.wsUrl} (sucursal $officeCode)'));
    _socket!.onDisconnect((_) => debugPrint('[Socket] Desconectado'));
    _socket!.onConnectError((data) => debugPrint('[Socket] Error de conexión: $data'));

    _socket!.onAny((event, data) {
      debugPrint('[Socket] Evento recibido → $event | data: $data');
      final cbs = _listeners[event.toString()];
      if (cbs != null) {
        for (final cb in List.of(cbs)) cb(data);
      }
    });

    for (final event in SocketEvent.values) {
      _socket!.on(event.value, (data) {
        debugPrint('[Socket] Procesando evento ${event.value}');
        _controllers[event]!.add(data);
      });
    }

    _socket!.connect();
  }

  void _teardownSocket() {
    if (_socket == null) return;
    _socket!.clearListeners();
    _socket!.disconnect();
    _socket!.dispose();
    _socket = null;
  }

  Stream<dynamic> on(SocketEvent event) => _controllers[event]!.stream;

  void addListener(SocketEvent event, void Function(dynamic) callback) {
    _listeners.putIfAbsent(event.value, () => []).add(callback);
  }

  void removeListener(SocketEvent event, void Function(dynamic) callback) {
    _listeners[event.value]?.remove(callback);
  }

  void disconnect() {
    _connectionCount = (_connectionCount - 1).clamp(0, 999);
    if (_connectionCount > 0) return;
    _closeAll();
    debugPrint('[Socket] Servicio desconectado');
  }

  /// Cierre forzado (logout): descarta todos los leases para que un socket
  /// con el token/sucursal de la sesión anterior no sobreviva.
  void reset() {
    _connectionCount = 0;
    _closeAll();
    debugPrint('[Socket] Servicio reiniciado');
  }

  void _closeAll() {
    _generation++;
    _teardownSocket();
    _currentOfficeCode = null;
  }
}
