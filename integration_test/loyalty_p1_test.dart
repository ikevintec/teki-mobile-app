import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../test/previews/loyalty_preview.dart' as preview;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('P1 nativo: listado, detalle, QR y portapapeles', (tester) async {
    preview.main();
    await tester.pumpAndSettle();
    if (defaultTargetPlatform == TargetPlatform.android) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
    }
    final platform = defaultTargetPlatform.name;
    Future<void> capture(String name) async {
      // Retira el indicador de toque del binding antes de capturar la UI.
      for (var frame = 0; frame < 4; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await binding.takeScreenshot(name);
    }

    await capture('$platform-listado');
    await tester.tap(find.text('Ver tarjeta').first);
    await tester.pumpAndSettle();
    await capture('$platform-detalle');
    await tester.tap(find.text('Mostrar QR'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsOneWidget);
    const url = 'https://example.com/fidelizacion/programa-demo';
    expect(find.text(url), findsOneWidget);
    await capture('$platform-qr');
    await tester.scrollUntilVisible(
      find.text('Copiar enlace'),
      160,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Copiar enlace'));
    await tester.pumpAndSettle();
    expect((await Clipboard.getData(Clipboard.kTextPlain))?.text, url);
    expect(find.text('Enlace copiado'), findsOneWidget);
    expect(tester.takeException(), null);
  });
}
