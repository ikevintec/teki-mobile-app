import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teki_app/src/presentation/screens/kitchen/widgets/kitchen_board.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    dotenv.loadFromString(envString: 'API_URL=http://localhost');
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpBoard(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: KitchenBoard())),
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

  testWidgets('muestra modalidades completas y permite limpiar el filtro', (
    tester,
  ) async {
    await pumpBoard(tester);

    expect(find.text('Todo'), findsOneWidget);
    expect(find.text('Para aquí'), findsOneWidget);
    expect(find.text('Llevar'), findsOneWidget);
    expect(find.text('Limpiar filtros'), findsNothing);

    await tester.tap(find.text('Llevar'));
    await tester.pump();

    expect(find.text('Limpiar filtros'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Limpiar filtros'));
    await tester.pump();

    expect(find.text('Limpiar filtros'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
