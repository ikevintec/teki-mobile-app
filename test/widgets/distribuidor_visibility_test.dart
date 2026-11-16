import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/domain/repositories/sale_station_repository.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/presentation/screens/sale/products/widgets/selector_precio_comercial.dart';
import 'package:teki_app/src/presentation/screens/sale/products/widgets/beneficios_venta.dart';
import 'package:teki_app/src/providers/config/config.dart';

class _Stations implements SaleStationRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Session extends SesionNotifier {
  _Session(Map<String, dynamic> config)
    : super(saleStationRepository: _Stations()) {
    state = state.copyWith(distribuidor: config, office: Office(id: 1));
  }
}

void main() {
  for (final config in <Map<String, dynamic>>[
    {},
    {'preciosComerciales': false, 'promociones': false},
  ]) {
    testWidgets(
      'sin configuración activa no aparecen controles nuevos: $config',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [sesionProvider.overrideWith((ref) => _Session(config))],
            child: const MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [SelectorPrecioComercial(), BeneficiosVenta()],
                ),
              ),
            ),
          ),
        );
        expect(find.byType(DropdownButtonFormField<int>), findsNothing);
        expect(find.text('Beneficios'), findsNothing);
      },
    );
  }
  testWidgets(
    'el selector muestra solo tipos compartidos o de la sede actual',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sesionProvider.overrideWith(
              (ref) => _Session({
                'preciosComerciales': true,
                'tipoPrecioCabeceraId': 1,
                'tipos': [
                  {'id': 1, 'nombre': 'Minorista', 'estado': true},
                  {
                    'id': 2,
                    'nombre': 'Mayorista Piura',
                    'estado': true,
                    'idPuntoVenta': 1,
                  },
                  {
                    'id': 3,
                    'nombre': 'Mayorista Guadalupe',
                    'estado': true,
                    'idPuntoVenta': 2,
                  },
                ],
              }),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SelectorPrecioComercial()),
          ),
        ),
      );
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      expect(find.text('Mayorista Piura'), findsOneWidget);
      expect(find.text('Mayorista Guadalupe'), findsNothing);
      await tester.tap(find.text('Mayorista Piura'));
      await tester.pumpAndSettle();
      expect(find.text('Mayorista Piura'), findsOneWidget);
    },
  );
}
