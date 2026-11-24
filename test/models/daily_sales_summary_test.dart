import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/response/daily_sales_summary.dart';

void main() {
  group('DailySalesSummary.ticketPromedio', () {
    test('divide el monto de la moneda entre el número de ventas', () {
      const s = DailySalesSummary(
        totalVentas: 4,
        montos: [
          MontoMonedaVenta(moneda: 'PEN', monto: 200.0),
          MontoMonedaVenta(moneda: 'USD', monto: 40.0),
        ],
      );
      expect(s.ticketPromedio('PEN'), 50.0);
      expect(s.ticketPromedio('USD'), 10.0);
    });

    test('sin ventas o sin la moneda devuelve 0', () {
      const vacio = DailySalesSummary();
      expect(vacio.ticketPromedio('PEN'), 0);

      const sinMoneda = DailySalesSummary(
        totalVentas: 2,
        montos: [MontoMonedaVenta(moneda: 'PEN', monto: 100.0)],
      );
      expect(sinMoneda.ticketPromedio('USD'), 0);
    });
  });
}
