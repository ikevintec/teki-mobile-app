import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../test/previews/loyalty_p2_preview.dart' as preview;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'P2 nativo: clientes, búsqueda, saldos, puntos y cupones por tarjeta',
    (tester) async {
      tester.testTextInput.register();
      addTearDown(tester.testTextInput.unregister);
      preview.main();
      await tester.pumpAndSettle();
      if (defaultTargetPlatform == TargetPlatform.android) {
        await binding.convertFlutterSurfaceToImage();
        await tester.pumpAndSettle();
      }
      final platform = defaultTargetPlatform.name.toLowerCase();
      Future<void> capture(String name) async {
        for (var frame = 0; frame < 4; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        await binding.takeScreenshot('$platform-p2-$name');
      }

      Future<void> scrollTo(String text) => tester.scrollUntilVisible(
        find.text(text),
        160,
        scrollable: find
            .descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Scrollable),
            )
            .first,
      );

      await tester.tap(find.text('Ver tarjeta').first);
      await tester.pumpAndSettle();
      await scrollTo('Clientes de esta tarjeta');
      await tester.tap(find.text('Clientes de esta tarjeta'));
      await tester.pumpAndSettle();
      expect(find.text('2 clientes'), findsOneWidget);
      await capture('clientes');
      await tester.enterText(find.byType(TextField), 'Luis');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('1 cliente encontrado'), findsOneWidget);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await capture('busqueda');
      await tester.enterText(find.byType(TextField), '');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      for (
        var attempt = 0;
        attempt < 40 && find.text('2 clientes').evaluate().isEmpty;
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      if (find.text('2 clientes').evaluate().isEmpty) {
        await capture('fallo-limpiar-busqueda');
      }
      expect(find.text('2 clientes'), findsOneWidget);
      await tester.tap(find.text('María de prueba'));
      await tester.pumpAndSettle();
      expect(find.text('14'), findsOneWidget);
      expect(find.text('Avance del ciclo: 4 de 10 sellos'), findsOneWidget);
      expect(find.text('40'), findsOneWidget);
      await capture('saldo');
      await scrollTo('Ver movimientos de puntos');
      await tester.tap(find.text('Ver movimientos de puntos'));
      await tester.pumpAndSettle();
      expect(find.text('-10 puntos'), findsOneWidget);
      expect(find.text('+50 puntos'), findsOneWidget);
      await capture('movimientos');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await scrollTo('Ver cupones emitidos');
      await tester.tap(find.text('Ver cupones emitidos'));
      await tester.pumpAndSettle();
      expect(find.text('Estado registrado: Usado'), findsOneWidget);
      expect(find.text('3 cupones emitidos'), findsOneWidget);
      await capture('cupones');
      for (var page = 0; page < 4; page++) {
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Ver tarjeta').last);
      await tester.pumpAndSettle();
      await scrollTo('Clientes de esta tarjeta');
      await tester.tap(find.text('Clientes de esta tarjeta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('María de prueba'));
      await tester.pumpAndSettle();
      expect(find.text('90'), findsOneWidget);
      expect(find.text('Sellos acumulados (histórico)'), findsNothing);
      await capture('otra-tarjeta');
      expect(tester.takeException(), null);
    },
  );
}
