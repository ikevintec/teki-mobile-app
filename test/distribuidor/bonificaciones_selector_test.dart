import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/presentation/screens/pedidos/bonificaciones_panel.dart';
import 'package:teki_app/src/providers/distribuidor/bonificaciones_provider.dart';

class SelectorNotifier extends BonificacionesNotifier {
  int? elegido;
  SelectorNotifier(super.ref, Map<String, dynamic> resultado) {
    state = BonificacionesState(resultado: resultado, vigente: true);
  }
  @override
  void elegirRegalo(int promo, int producto) {
    elegido = producto;
  }
}

void main() {
  for (final size in [const Size(390, 844), const Size(1024, 768)]) {
    for (final anterior in [false, true]) {
      testWidgets('selector cantidades/stock a $size API anterior=$anterior', (
        t,
      ) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final eleccion = <String, dynamic>{
          'idPromocion': 10,
          'nombre': 'Regalos distintos',
          'cantidad': 2,
          'opciones': [2, 3],
          if (!anterior) 'cantidadesPorOpcion': {'2': 2, '3': 1},
        };
        late SelectorNotifier notifier;
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              bonificacionesProvider.overrideWith(
                (ref) => notifier = SelectorNotifier(ref, {
                  'regalos': {
                    '2': {
                      'nombre': 'Regalo agotado',
                      'unidad': 'NIU',
                      'disponible': 0,
                    },
                    '3': {
                      'nombre': 'Regalo disponible',
                      'unidad': 'MTR',
                      'disponible': 1,
                    },
                  },
                }),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    ref.watch(bonificacionesProvider);
                    return TextButton(
                      onPressed: () =>
                          elegirRegaloBonificacion(context, ref, eleccion),
                      child: const Text('Elegir'),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await t.tap(find.text('Elegir'));
        await t.pumpAndSettle();
        final agotado = t.widget<ListTile>(
          find.ancestor(
            of: find.text('Regalo agotado'),
            matching: find.byType(ListTile),
          ),
        );
        expect(agotado.enabled, anterior);
        final valido = t.widget<ListTile>(
          find.ancestor(
            of: find.text('Regalo disponible'),
            matching: find.byType(ListTile),
          ),
        );
        expect(valido.enabled, isTrue);
        expect(
          find.textContaining(anterior ? '2 m de regalo' : '1 m de regalo'),
          findsOneWidget,
        );
        await t.tap(find.text('Regalo disponible'));
        await t.pumpAndSettle();
        expect(notifier.elegido, 3);
        expect(t.takeException(), isNull);
      });
    }
  }
}
