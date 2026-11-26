import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:teki_app/src/presentation/screens/sale/products/widgets/product_item_card.dart';

void main() {
  testWidgets('cantidad bloqueada no permite abrir modal ni cambiar valor', (
    t,
  ) async {
    final form = FormGroup({'quantity': FormControl<double>(value: 2)});
    var cambios = 0;
    await t.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ReactiveForm(
              formGroup: form,
              child: QuantityControl(
                formGroup: form,
                locked: true,
                onQuantityChanged: () => cambios++,
              ),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('x2'), warnIfMissed: false);
    await t.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(form.control('quantity').value, 2);
    expect(cambios, 0);
  });

  testWidgets(
    'más y menos conservan fracciones y notifican una vez por cambio',
    (t) async {
      final form = FormGroup({'quantity': FormControl<double>(value: 1.5)});
      var cambios = 0;
      await t.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QuantityControl(
                formGroup: form,
                onQuantityChanged: () => cambios++,
              ),
            ),
          ),
        ),
      );
      await t.tap(find.byIcon(Icons.remove));
      await t.pumpAndSettle();
      expect(find.text('0.5'), findsOneWidget);
      await t.tap(find.byIcon(Icons.remove));
      await t.pumpAndSettle();
      expect(form.control('quantity').value, .5);
      expect(cambios, 1);
      await t.tap(find.byIcon(Icons.add));
      await t.pumpAndSettle();
      expect(form.control('quantity').value, 1.5);
      expect(cambios, 2);
    },
  );

  testWidgets('modal actualiza solo su línea al aceptar y volver cancela', (
    t,
  ) async {
    final forms = [
      for (final qty in [1.0, 3.0])
        FormGroup({'quantity': FormControl<double>(value: qty)}),
    ];
    final cambios = [0, 0];
    await t.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                for (var i = 0; i < forms.length; i++)
                  QuantityControl(
                    formGroup: forms[i],
                    onQuantityChanged: () => cambios[i]++,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('3'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextFormField), '12.75');
    await t.tap(find.text('Aceptar'));
    await t.pumpAndSettle();
    expect(forms[0].control('quantity').value, 1);
    expect(forms[1].control('quantity').value, 12.75);
    expect(cambios, [0, 1]);
    await t.tap(find.text('12.75'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextFormField), '99');
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(forms[1].control('quantity').value, 12.75);
    expect(cambios, [0, 1]);
    expect(t.takeException(), isNull);
  });
}
