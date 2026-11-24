import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/preparation.dart';
import 'package:teki_app/src/data/models/teki_model/preparation_option.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/product_preparation.dart';
import 'package:teki_app/src/presentation/screens/restaurant/comanda/product_detail/preparaciones_section.dart';
import 'package:teki_app/src/providers/restaurant/comanda_item_form.dart';

Product _producto({required bool multiple}) => Product(preparaciones: [
      ProductPreparation(
        requerido: true,
        preparacion: Preparation(
          id: 17,
          nombre: 'TERMINO DE CARNE',
          seleccionMultiple: multiple,
          opciones: [
            PreparationOption(id: 34, opcion: 'TERMINO MEDIO'),
            PreparationOption(id: 35, opcion: '3/4'),
          ],
        ),
      ),
    ]);

/// Monta la sección con el mismo estado/toggle que usa ProductDetailSheet.
Future<Map<int, Set<int>>> _pump(WidgetTester tester, Product product) async {
  final selections = <int, Set<int>>{};
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: StatefulBuilder(
        builder: (context, setState) => PreparacionesSection(
          product: product,
          prepSelections: selections,
          onToggle: (prepId, opcionId, multiple) => setState(
            () => selections[prepId] = ComandaItemForm.togglePreparacion(
              current: selections[prepId] ?? <int>{},
              opcionId: opcionId,
              seleccionMultiple: multiple,
            ),
          ),
        ),
      ),
    ),
  ));
  return selections;
}

void main() {
  testWidgets('selección múltiple muestra checkboxes y acumula opciones',
      (tester) async {
    final selections = await _pump(tester, _producto(multiple: true));

    expect(find.text('Puedes elegir varias opciones'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNWidgets(2));
    expect(find.byType(RadioListTile<int>), findsNothing);

    await tester.tap(find.text('TERMINO MEDIO'));
    await tester.pump();
    await tester.tap(find.text('3/4'));
    await tester.pump();
    expect(selections[17], {34, 35});

    await tester.tap(find.text('TERMINO MEDIO'));
    await tester.pump();
    expect(selections[17], {35});
  });

  testWidgets('selección única usa radio, reemplaza y permite desmarcar',
      (tester) async {
    final selections = await _pump(tester, _producto(multiple: false));

    expect(find.text('Puedes elegir varias opciones'), findsNothing);
    expect(find.byType(RadioListTile<int>), findsNWidgets(2));

    await tester.tap(find.text('TERMINO MEDIO'));
    await tester.pump();
    await tester.tap(find.text('3/4'));
    await tester.pump();
    expect(selections[17], {35});

    await tester.tap(find.text('3/4'));
    await tester.pump();
    expect(selections[17], isEmpty);
  });
}
