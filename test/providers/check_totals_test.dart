import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail.dart';
import 'package:teki_app/src/providers/restaurant/check_totals.dart';

void main() {
  group('checkItemsTotal', () {
    test('excluye items CANCELADO (paridad web)', () {
      final items = [
        CommandDetail(precioVenta: 15.0, cantidad: 2), // 30 válidos
        CommandDetail(
            precioVenta: 15.0, cantidad: 1, estadoComandaDetalle: 'CANCELADO'),
      ];
      expect(checkItemsTotal(items), 30.0); // no 45
    });

    test('estado en minúsculas también cuenta como cancelado', () {
      final items = [
        CommandDetail(precioVenta: 10.0, cantidad: 1),
        CommandDetail(
            precioVenta: 99.0, cantidad: 1, estadoComandaDetalle: 'cancelado'),
      ];
      expect(checkItemsTotal(items), 10.0);
    });

    test('lista nula o vacía es 0', () {
      expect(checkItemsTotal(null), 0);
      expect(checkItemsTotal(const []), 0);
    });
  });
}
