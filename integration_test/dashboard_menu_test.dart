import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../test/previews/dashboard_preview.dart' as preview;
import '../test/support/dashboard_fixture.dart';

Future<void> pumpDashboard(WidgetTester tester) async {
  // El orbe del asistente mantiene una animación continua: esperar cuadros
  // acotados, sin pedir que toda la app deje de animarse.
  for (var frame = 0; frame < 12; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'menú nativo con todos los accesos, lectura y permisos revocados',
    (tester) async {
      await preview.main();
      await pumpDashboard(tester);
      if (defaultTargetPlatform == TargetPlatform.android) {
        await binding.convertFlutterSurfaceToImage();
        await pumpDashboard(tester);
      }
      Future<void> capture(String name) async {
        await pumpDashboard(tester);
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await binding.takeScreenshot(
          '${defaultTargetPlatform.name}-menu-$name',
        );
      }

      expect(find.text('Más opciones'), findsNothing);
      expect(find.byKey(const ValueKey('tab-customers')), findsOneWidget);
      await capture('todos-inicio');
      final scroll = find.byType(Scrollable).first;
      await tester.drag(scroll, const Offset(0, -550));
      await capture('todos-grupos');
      await tester.drag(scroll, const Offset(0, -700));
      await capture('todos-restaurante');
      await tester.tap(find.byKey(const ValueKey('tab-customers')));
      await pumpDashboard(tester);
      expect(find.text('Cliente de demostración'), findsOneWidget);
      expect(find.text('Crear cliente'), findsOneWidget);
      await capture('clientes');
      preview.previewSession!.replace(
        dashboardSession(roles: ['CLIENTES_VER'], features: false),
      );
      await pumpDashboard(tester);
      expect(find.text('Crear cliente'), findsNothing);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      await capture('clientes-solo-lectura');
      preview.previewSession!.replace(
        dashboardSession(roles: [], features: false),
      );
      await pumpDashboard(tester);
      expect(find.byKey(const ValueKey('tab-customers')), findsNothing);
      expect(find.text('Cliente de demostración'), findsNothing);
      await capture('sin-permisos');
      preview.previewSession!.replace(
        dashboardSession(roles: ['VENTAS_CREAR'], features: false),
      );
      await pumpDashboard(tester);
      expect(find.byKey(const ValueKey('quick-sale')), findsOneWidget);
      await capture('solo-crear-ventas');
      expect(tester.takeException(), null);
    },
  );
}
