import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/response/login.dart';
import 'package:teki_app/src/providers/config/config.dart';

void main() {
  group('SesionState.hasPermission', () {
    test('true cuando el rol está en la lista', () {
      final state = SesionState(
        login: LoginResponse(),
        roles: const ['CAJA_VER', 'CAJA_INGRESO_EGRESO_CREAR'],
      );
      expect(state.hasPermission('CAJA_VER'), isTrue);
      expect(state.hasPermission('CAJA_INGRESO_EGRESO_CREAR'), isTrue);
    });

    test('false cuando el rol no está', () {
      final state = SesionState(
        login: LoginResponse(),
        roles: const ['CAJA_VER'],
      );
      expect(state.hasPermission('CAJA_CERRAR'), isFalse);
    });

    test('false con roles null o vacíos', () {
      expect(
        SesionState(login: LoginResponse()).hasPermission('CAJA_VER'),
        isFalse,
      );
      expect(
        SesionState(login: LoginResponse(), roles: const [])
            .hasPermission('CAJA_VER'),
        isFalse,
      );
    });
  });
}
