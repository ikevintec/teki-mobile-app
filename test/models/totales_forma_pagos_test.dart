import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/totales_forma_pagos.dart';

void main() {
  test('fromFlatJsonList agrupa la respuesta plana del backend por moneda', () {
    // Shape real del endpoint (igual que consume la web antes de su reduce).
    final raw = [
      {'codigoMoneda': 'PEN', 'metodoPago': 'YAPE', 'monto': 5043.88},
      {'codigoMoneda': 'PEN', 'metodoPago': 'Pago en efectivo', 'monto': 5840.6},
      {'codigoMoneda': 'PEN', 'metodoPago': 'Visa', 'monto': 100},
      {'codigoMoneda': 'USD', 'metodoPago': 'YAPE', 'monto': 5.88},
    ];

    final grupos = TotalVentasFormaPago.fromFlatJsonList(raw);

    expect(grupos, hasLength(2));
    final pen = grupos.firstWhere((g) => g.codigoMoneda == 'PEN');
    expect(pen.metodosPago, hasLength(3));
    expect(pen.metodosPago.map((m) => m.metodoPago),
        containsAll(['YAPE', 'Pago en efectivo', 'Visa']));
    expect(
      pen.metodosPago.firstWhere((m) => m.metodoPago == 'YAPE').monto,
      5043.88,
    );
    final usd = grupos.firstWhere((g) => g.codigoMoneda == 'USD');
    expect(usd.metodosPago.single.monto, 5.88);
  });

  test('lista vacía produce cero grupos', () {
    expect(TotalVentasFormaPago.fromFlatJsonList(const []), isEmpty);
  });
}
