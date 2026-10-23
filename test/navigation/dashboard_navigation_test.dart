import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/presentation/screens/dashboard/navigation/dashboard_navigation.dart';
import '../support/loyalty_fixture.dart';

void main() {
  test('sin roles solo Inicio y ajustes; no hay grupos vacíos', () {
    final session = loyaltySession(roles: []);
    expect(dashboardDestinations(session), [DashboardDestination.home]);
    expect(dashboardQuickActions(session), isEmpty);
    expect(dashboardGroups(session).map((g) => g.label), ['Administración']);
    expect(dashboardGroups(session).single.actions, [DashboardAction.settings]);
  });
  test('vendedor creador no recibe clientes, reportes ni listados', () {
    final session = loyaltySession(roles: ['VENTAS_CREAR']);
    final actions = dashboardGroups(session).expand((g) => g.actions);
    expect(
      actions,
      containsAll([DashboardAction.sale, DashboardAction.newQuotation]),
    );
    expect(actions, isNot(contains(DashboardAction.quotations)));
    expect(actions, isNot(contains(DashboardAction.analytics)));
    expect(dashboardQuickActions(session), [DashboardAction.sale]);
  });
  test('consulta no concede crear ventas; clientes tiene tab estable', () {
    final session = loyaltySession(
      roles: ['CLIENTES_VER', 'VENTAS_VER', 'COTIZACION_VER'],
    );
    expect(dashboardDestinations(session), [
      DashboardDestination.home,
      DashboardDestination.customers,
    ]);
    expect(dashboardQuickActions(session), [
      DashboardAction.vouchers,
      DashboardAction.quotations,
    ]);
  });
  test('superusuario no habilita funciones apagadas de empresa', () {
    final session = loyaltySession(roles: ['SUPER_USUARIO'], enabled: false);
    expect(dashboardDestinations(session), DashboardDestination.values);
    final actions = dashboardGroups(session).expand((g) => g.actions);
    expect(actions, isNot(contains(DashboardAction.loyalty)));
    expect(actions, isNot(contains(DashboardAction.containers)));
    expect(actions, isNot(contains(DashboardAction.tables)));
    expect(actions, isNot(contains(DashboardAction.yape)));
  });
  test('todos los accesos conservan agrupación, funciones y prioridad', () {
    final session = loyaltySession(roles: ['SUPER_USUARIO'], containers: true);
    session.config!.inventario = true;
    session.config!.esRestaurante = true;
    session.config!.verNotificacionYape = true;
    expect(dashboardQuickActions(session).length, 6);
    final groups = dashboardGroups(session);
    expect(groups.every((g) => g.actions.isNotEmpty), isTrue);
    expect(
      groups
          .singleWhere((g) => g.label == 'Inventario y abastecimiento')
          .actions,
      containsAll([
        DashboardAction.products,
        DashboardAction.transfers,
        DashboardAction.purchases,
      ]),
    );
    expect(
      groups.singleWhere((g) => g.label == 'Restaurante').actions.length,
      4,
    );
  });
  test(
    'envases requiere inventario y flag, fidelización su propio permiso',
    () {
      final session = loyaltySession(
        roles: ['INVENTARIO_VER'],
        containers: true,
      );
      var actions = dashboardGroups(session).expand((g) => g.actions);
      expect(actions, isNot(contains(DashboardAction.containers)));
      session.config!.inventario = true;
      actions = dashboardGroups(session).expand((g) => g.actions);
      expect(actions, contains(DashboardAction.containers));
      expect(actions, isNot(contains(DashboardAction.loyalty)));
    },
  );
  test('cocina solo visible para restaurante y con su permiso', () {
    final session = loyaltySession(roles: ['RESTAURANTE_COCINA_VER']);
    expect(
      dashboardGroups(session).any((g) => g.label == 'Restaurante'),
      isFalse,
    );
    session.config!.esRestaurante = true;
    expect(
      dashboardGroups(
        session,
      ).singleWhere((g) => g.label == 'Restaurante').actions,
      [DashboardAction.kitchen],
    );
  });
}
