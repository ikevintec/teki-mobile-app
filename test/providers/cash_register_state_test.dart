import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/response/cash_register_response.dart';
import 'package:teki_app/src/providers/cash_register/cash_register_provider.dart';

CashRegisterResponse register({
  List<MontoMoneda> ingresos = const [],
  List<MontoMoneda> egresos = const [],
}) {
  return CashRegisterResponse(
    id: 1,
    montosTotalesIngresos: ingresos,
    montosTotalesEgresos: egresos,
    montosIngresosEfectivo: const [],
  );
}

void main() {
  group('CashRegisterState.monedas', () {
    test('PEN va siempre primero', () {
      final state = CashRegisterState(registers: [
        register(ingresos: [
          MontoMoneda(monto: 10, moneda: 'USD'),
          MontoMoneda(monto: 20, moneda: 'PEN'),
        ]),
      ]);
      expect(state.monedas.first, 'PEN');
      expect(state.monedas, containsAll(['PEN', 'USD']));
    });

    test('sin registros no hay monedas', () {
      expect(const CashRegisterState().monedas, isEmpty);
    });
  });

  group('CashRegisterState.monedaActiva', () {
    final state = CashRegisterState(registers: [
      register(ingresos: [
        MontoMoneda(monto: 10, moneda: 'USD'),
        MontoMoneda(monto: 20, moneda: 'PEN'),
      ]),
    ]);

    test('respeta la selección si sigue disponible', () {
      expect(state.monedaActiva('USD'), 'USD');
    });

    test('selección no disponible cae a PEN', () {
      expect(state.monedaActiva('EUR'), 'PEN');
      expect(state.monedaActiva(null), 'PEN');
    });

    test('sin PEN cae a la primera disponible', () {
      final soloUsd = CashRegisterState(registers: [
        register(ingresos: [MontoMoneda(monto: 10, moneda: 'USD')]),
      ]);
      expect(soloUsd.monedaActiva(null), 'USD');
    });

    test('sin monedas retorna PEN por defecto', () {
      expect(const CashRegisterState().monedaActiva(null), 'PEN');
    });
  });

  group('CashRegisterState.openRegisterEsOtraFecha', () {
    final hoy = DateTime(2026, 7, 22);

    test('sin caja abierta no hay aviso', () {
      expect(const CashRegisterState().openRegisterEsOtraFecha(hoy), isFalse);
    });

    test('caja abierta del mismo día no genera aviso', () {
      final state = CashRegisterState(
        openRegister: CashRegisterResponse(
          id: 1,
          estadoCaja: 'APERTURADA',
          fecha: DateTime(2026, 7, 22, 18, 30),
          montosTotalesIngresos: const [],
          montosTotalesEgresos: const [],
          montosIngresosEfectivo: const [],
        ),
      );
      expect(state.openRegisterEsOtraFecha(hoy), isFalse);
    });

    test('caja abierta de otro día genera aviso', () {
      final state = CashRegisterState(
        openRegister: CashRegisterResponse(
          id: 1,
          estadoCaja: 'APERTURADA',
          fecha: DateTime(2026, 7, 19),
          montosTotalesIngresos: const [],
          montosTotalesEgresos: const [],
          montosIngresosEfectivo: const [],
        ),
      );
      expect(state.openRegisterEsOtraFecha(hoy), isTrue);
    });

    test('caja abierta sin fecha no genera aviso', () {
      final state = CashRegisterState(
        openRegister: CashRegisterResponse(
          id: 1,
          montosTotalesIngresos: const [],
          montosTotalesEgresos: const [],
          montosIngresosEfectivo: const [],
        ),
      );
      expect(state.openRegisterEsOtraFecha(hoy), isFalse);
    });
  });

  group('CashRegisterState.copyWith y openRegister', () {
    final caja = CashRegisterResponse(
      id: 9,
      montosTotalesIngresos: const [],
      montosTotalesEgresos: const [],
      montosIngresosEfectivo: const [],
    );

    test('copyWith sin openRegister lo conserva', () {
      final state = CashRegisterState(openRegister: caja);
      expect(state.copyWith(isLoading: true).openRegister, same(caja));
    });

    test('copyWith puede limpiar openRegister con null explícito', () {
      final state = CashRegisterState(openRegister: caja);
      expect(state.copyWith(openRegister: null).openRegister, isNull);
    });
  });

  group('CashRegisterResponse', () {
    test('isAperturada según estadoCaja', () {
      expect(register().isAperturada, isFalse);
      final abierta = CashRegisterResponse(
        estadoCaja: 'APERTURADA',
        montosTotalesIngresos: const [],
        montosTotalesEgresos: const [],
        montosIngresosEfectivo: const [],
      );
      expect(abierta.isAperturada, isTrue);
    });

    test('fromJson parsea la fecha en formatos flexibles', () {
      final r = CashRegisterResponse.fromJson({
        'id': 1,
        'estadoCaja': 'APERTURADA',
        'fecha': '2026-07-19T00:00:00',
      });
      expect(r.fecha, DateTime(2026, 7, 19));
    });
  });

  group('CashRegisterState.balancePorMoneda', () {
    test('ingresos menos egresos por moneda', () {
      final state = CashRegisterState(registers: [
        register(
          ingresos: [MontoMoneda(monto: 100, moneda: 'PEN')],
          egresos: [MontoMoneda(monto: 30, moneda: 'PEN')],
        ),
        register(ingresos: [MontoMoneda(monto: 50, moneda: 'PEN')]),
      ]);
      expect(state.balancePorMoneda['PEN'], 120.0);
    });
  });
}
