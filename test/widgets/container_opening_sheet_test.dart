import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/domain/repositories/sale_station_repository.dart';
import 'package:teki_app/src/presentation/screens/container_loans/widgets/container_opening_sheet.dart';
import 'package:teki_app/src/providers/config/config.dart';
import '../support/envase_sale_fixture.dart';

class _Stations implements SaleStationRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Session extends SesionNotifier {
  _Session() : super(saleStationRepository: _Stations()) {
    state = testSesion.copyWith(offices: [Office(id: 1, nombre: 'San Isidro')]);
  }
}

void main() {
  testWidgets(
    'explica ambos efectos de stock y permite revisar costo sin sobrecargar el formulario',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sesionProvider.overrideWith((ref) => _Session())],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: const Scaffold(body: ContainerOpeningSheet()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('No registra una venta.'), findsOneWidget);
      expect(find.text('Préstamo anterior'), findsNothing);
      final quantity = find.widgetWithText(TextField, 'Envases por devolver');
      await tester.ensureVisible(quantity);
      await tester.enterText(quantity, '5');
      await tester.pumpAndSettle();
      final yes = find.text('Sí, ya los desconté');
      await tester.ensureVisible(yes);
      await tester.tap(yes);
      await tester.pumpAndSettle();
      expect(find.text('Mantener el stock actual.'), findsOneWidget);
      final no = find.text('No, todavía aparecen en stock');
      await tester.ensureVisible(no);
      await tester.tap(no);
      await tester.pumpAndSettle();
      expect(
        find.text('Descontar 5 envases vacíos de la sede elegida.'),
        findsOneWidget,
      );
      final details = find.text('Valor y observación');
      await tester.ensureVisible(details);
      await tester.tap(details);
      await tester.pumpAndSettle();
      final note = find.widgetWithText(TextField, 'Observación (opcional)');
      await tester.ensureVisible(note);
      expect(note, findsOneWidget);
      expect(find.textContaining('No se cobra al cliente.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final save = find.widgetWithText(FilledButton, 'Registrar pendientes');
      await tester.ensureVisible(save);
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
    },
  );
}
