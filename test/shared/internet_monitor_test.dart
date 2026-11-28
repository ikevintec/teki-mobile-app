import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/shared/services/internet_monitor.dart';

void main() {
  test('desconexión, recuperación y comprobaciones concurrentes', () async {
    final result = Completer<bool>();
    var calls = 0;
    final monitor = InternetMonitor(
      check: () {
        calls++;
        return result.future;
      },
    );
    addTearDown(monitor.dispose);
    expect(monitor.value, InternetState.unknown);
    final first = monitor.refresh();
    final second = monitor.refresh();
    expect(calls, 1);
    result.complete(false);
    expect(await first, InternetState.disconnected);
    expect(await second, InternetState.disconnected);
    monitor.markReachable();
    expect(monitor.value, InternetState.connected);
    // Aunque la comprobación anterior ya informó offline, la próxima se aplica.
    expect(await monitor.refresh(), InternetState.disconnected);
  });

  test(
    'una comprobación antigua no pisa una respuesta HTTP más reciente',
    () async {
      final result = Completer<bool>();
      final monitor = InternetMonitor(check: () => result.future);
      addTearDown(monitor.dispose);
      final check = monitor.refresh();
      monitor.markReachable();
      result.complete(false);
      expect(await check, InternetState.connected);
    },
  );

  test('un fallo del detector conserva estado desconocido', () async {
    final monitor = InternetMonitor(
      check: () async => throw StateError('detector'),
    );
    addTearDown(monitor.dispose);
    expect(await monitor.refresh(), InternetState.unknown);
  });

  testWidgets('pausa detiene sondeos y reanudar comprueba de nuevo', (
    tester,
  ) async {
    var calls = 0;
    final monitor = InternetMonitor(
      check: () async {
        calls++;
        return false;
      },
    );
    addTearDown(monitor.dispose);
    monitor.start();
    await tester.pump();
    expect(calls, 1);
    await tester.pump(const Duration(seconds: 10));
    expect(calls, 2);
    monitor.stop();
    await tester.pump(const Duration(seconds: 30));
    expect(calls, 2);
    monitor.start();
    await tester.pump();
    expect(calls, 3);
    monitor.stop();
  });
}
