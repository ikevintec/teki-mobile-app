import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

enum InternetState { unknown, connected, disconnected }

/// Comprueba acceso real a Internet, independientemente de la API de Teki.
class InternetMonitor extends ValueNotifier<InternetState> {
  InternetMonitor({
    required Future<bool> Function() check,
    this.interval = const Duration(seconds: 10),
  }) : _check = check,
       super(InternetState.unknown);

  static final instance = InternetMonitor(
    check: () => InternetConnection().hasInternetAccess,
  );

  final Future<bool> Function() _check;
  final Duration interval;
  Timer? _timer;
  Future<InternetState>? _pending;
  int _revision = 0;
  bool _disposed = false;

  void start() {
    if (_timer != null || _disposed) return;
    _timer = Timer.periodic(interval, (_) => unawaited(refresh()));
    unawaited(refresh());
  }

  void stop() {
    _revision++;
    _timer?.cancel();
    _timer = null;
    _pending = null;
  }

  void _update(bool connected) {
    _revision++;
    if (!_disposed) {
      value = connected ? InternetState.connected : InternetState.disconnected;
    }
  }

  /// Una respuesta HTTP, incluso 5xx, demuestra que existe conexión.
  void markReachable() => _update(true);

  Future<InternetState> refresh() {
    if (_pending != null) return _pending!;
    late final Future<InternetState> task;
    task = _refresh().whenComplete(() {
      if (identical(_pending, task)) _pending = null;
    });
    _pending = task;
    return task;
  }

  Future<InternetState> _refresh() async {
    final revision = _revision;
    try {
      final connected = await _check().timeout(const Duration(seconds: 6));
      if (!_disposed && revision == _revision) _update(connected);
    } catch (_) {
      // Conservar el estado: un error interno no prueba que falte Internet.
    }
    return value;
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    super.dispose();
  }
}
