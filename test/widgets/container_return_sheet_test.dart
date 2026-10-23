import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/container_loan.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/domain/repositories/container_loan_repository.dart';
import 'package:teki_app/src/domain/repositories/sale_station_repository.dart';
import 'package:teki_app/src/presentation/screens/container_loans/widgets/container_return_sheet.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/container_loans/container_loans_provider.dart';
import '../support/envase_sale_fixture.dart';

class _Stations implements SaleStationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Session extends SesionNotifier {
  _Session() : super(saleStationRepository: _Stations()) {
    state = testSesion.copyWith(offices: [Office(id: 1, nombre: 'San Isidro')]);
  }
}

class _Repository implements ContainerLoanRepository {
  final requests = <ContainerReturn>[];
  final response = Completer<ContainerLoan>();
  @override
  Future<ContainerLoan> receive(int loanId, ContainerReturn request) {
    requests.add(request);
    return response.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<void> open(WidgetTester tester, _Repository repo) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sesionProvider.overrideWith((ref) => _Session()),
          containerLoanRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ContainerReturnSheet(
              loan: ContainerLoan(
                id: 1,
                customer: 'Cliente de prueba',
                container: 'Bidón vacío',
                pendingQuantity: 250,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final quantity = find.widgetWithText(TextField, 'Cantidad recibida');
  FilledButton button(WidgetTester tester) => tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, 'Confirmar devolución'),
  );
  testWidgets(
    'permite escribir 100, ajustar con botones y enviar una sola devolución parcial',
    (tester) async {
      final repo = _Repository();
      await open(tester, repo);
      await tester.enterText(quantity, '100');
      await tester.pump();
      expect(
        find.textContaining('150 envases', findRichText: true),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Agregar un envase'));
      await tester.pump();
      expect(
        find.textContaining('149 envases', findRichText: true),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Quitar un envase'));
      await tester.pump();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Confirmar devolución'),
      );
      await tester.pump();
      expect(repo.requests.single.quantity, 100);
      expect(repo.requests.single.officeId, 1);
      expect(repo.requests.single.requestId, isNotEmpty);
      expect(button(tester).onPressed, isNull);
      // Cierra la vista mientras el servidor sigue atendiendo la solicitud.
      await tester.pumpWidget(const SizedBox());
      repo.response.complete(const ContainerLoan(pendingQuantity: 150));
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'vacío, cero y exceso bloquean guardar; el saldo exacto es válido',
    (tester) async {
      await open(tester, _Repository());
      for (final invalid in ['', '0', '251']) {
        await tester.enterText(quantity, invalid);
        await tester.pump();
        expect(button(tester).onPressed, isNull);
      }
      expect(find.text('Solo hay 250 envases por devolver.'), findsOneWidget);
      await tester.enterText(quantity, '250');
      await tester.pump();
      expect(button(tester).onPressed, isNotNull);
      expect(
        find.text(
          'El cliente quedará sin envases pendientes.',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is IconButton &&
                    widget.tooltip == 'Agregar un envase',
              ),
            )
            .onPressed,
        isNull,
      );
    },
  );
  testWidgets(
    'pantalla pequeña con teclado conserva formulario desplazable sin overflow',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await open(tester, _Repository());
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      await tester.enterText(quantity, '100');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Confirmar devolución'),
      );
      expect(button(tester).onPressed, isNotNull);
    },
  );
}
