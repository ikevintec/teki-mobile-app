import 'dart:async';

import 'package:teki_app/src/data/models/teki_model/restaurant_event.dart';
import 'package:teki_app/src/shared/services/socket_service.dart';

class RestaurantEventsService {
  static const _duplicateWindow = Duration(seconds: 3);

  final SocketService socketService;
  final Map<String, DateTime> _recentEvents = {};
  StreamSubscription<dynamic>? _commandSubscription;
  StreamSubscription<dynamic>? _orderSubscription;
  void Function(RestaurantEvent event)? _listener;

  RestaurantEventsService({SocketService? socketService})
    : socketService = socketService ?? SocketService();

  void listen(void Function(RestaurantEvent event) listener) {
    _listener = listener;
    _commandSubscription ??= socketService
        .on(SocketEvent.commandRestaurant)
        .listen((raw) => _handle(raw, isOrderChannel: false));
    _orderSubscription ??= socketService
        .on(SocketEvent.orderRestaurant)
        .listen((raw) => _handle(raw, isOrderChannel: true));
  }

  void _handle(dynamic raw, {required bool isOrderChannel}) {
    final event = RestaurantEvent.fromSocket(
      raw,
      isOrderChannel: isOrderChannel,
    );
    if (event == null || _isDuplicate(event)) return;
    _listener?.call(event);
  }

  bool _isDuplicate(RestaurantEvent event) {
    final timestamp = event.timestamp;
    if (timestamp == null) return false;

    final now = DateTime.now();
    _recentEvents.removeWhere(
      (_, seenAt) => now.difference(seenAt) > _duplicateWindow,
    );
    final key = event.duplicateKey;
    if (_recentEvents.containsKey(key)) return true;
    _recentEvents[key] = now;
    return false;
  }

  Future<void> dispose() async {
    await _commandSubscription?.cancel();
    await _orderSubscription?.cancel();
    _commandSubscription = null;
    _orderSubscription = null;
    _listener = null;
    _recentEvents.clear();
  }
}
