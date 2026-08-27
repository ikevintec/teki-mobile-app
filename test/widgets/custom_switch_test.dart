import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/presentation/widgets/switch/custom_switch.dart';

void main() {
  testWidgets('se renderiza como hijo no flexible de un Row', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              const Text('Pago'),
              const Spacer(),
              CustomSwitch(
                small: true,
                title: 'Agrupar ítems',
                border: false,
                value: false,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Agrupar ítems'), findsOneWidget);
  });

  testWidgets('trunca el título cuando el ancho es limitado', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 140,
              child: CustomSwitch(
                title: 'Un título localizado considerablemente largo',
                value: true,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final title = tester.widget<Text>(
      find.text('Un título localizado considerablemente largo'),
    );
    expect(title.maxLines, 1);
    expect(title.overflow, TextOverflow.ellipsis);
  });
}
