import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teki_app/src/presentation/screens/kitchen/widgets/kitchen_board.dart';
import 'package:teki_app/src/providers/kitchen/kitchen_provider.dart';
import 'package:teki_app/src/providers/kitchen/kitchen_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    dotenv.loadFromString(envString: 'API_URL=http://localhost');
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpBoard(WidgetTester tester, {double textScale = 1}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const Scaffold(body: KitchenBoard()),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('muestra todos los estados sin desplazamiento horizontal', (
    tester,
  ) async {
    await pumpBoard(tester);

    expect(find.text('Pendientes'), findsOneWidget);
    expect(find.text('Listos'), findsOneWidget);
    expect(find.text('Servidos'), findsOneWidget);
    expect(find.text('Anulados'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final textScale in [1.0, 2.0]) {
    testWidgets(
      'modalidades y limpieza de filtros a 320px con texto x$textScale',
      (tester) async {
        await pumpBoard(tester, textScale: textScale);

        final container = ProviderScope.containerOf(
          tester.element(find.byType(KitchenBoard)),
        );
        final notifier = container.read(kitchenProvider.notifier);

        expect(find.text('Todos'), findsOneWidget);
        expect(find.text('Aquí'), findsOneWidget);
        expect(find.text('Llevar'), findsOneWidget);
        expect(find.text('Limpiar'), findsNothing);
        expect(
          container.read(kitchenProvider).filters.mode,
          KitchenOrderMode.all,
        );

        await tester.tap(find.text('Llevar'));
        await tester.pump();

        expect(find.text('Limpiar'), findsOneWidget);
        expect(
          container.read(kitchenProvider).filters.mode,
          KitchenOrderMode.takeaway,
        );
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Aquí'));
        await tester.pump();
        expect(
          container.read(kitchenProvider).filters.mode,
          KitchenOrderMode.dineIn,
        );

        // Limpiar elimina modalidad y áreas, sin cambiar la pestaña de estados.
        notifier.setView(KitchenView.ready);
        await notifier.setProductionAreas([1, 2]);
        await tester.pump();
        expect(find.text('Limpiar (2)'), findsOneWidget);

        await tester.tap(find.text('Limpiar (2)'));
        await tester.pump();

        final filters = container.read(kitchenProvider).filters;
        expect(filters.mode, KitchenOrderMode.all);
        expect(filters.productionAreaIds, isEmpty);
        expect(filters.view, KitchenView.ready);

        expect(find.text('Limpiar'), findsNothing);
        expect(find.text('Limpiar (2)'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
