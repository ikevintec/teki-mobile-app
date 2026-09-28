import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/payment_detail.dart';
import 'package:teki_app/src/data/models/teki_model/payment_method.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';

void main() {
  test('serializa los mismos campos de propina que la web', () {
    final ticket = Ticket(
      propina: 8.5,
      mozoResponsable: User(id: 12, nombreCompleto: 'Ana Mozo'),
      pagosPropina: [
        PaymentDetail(
          monto: 8.5,
          montoPagado: 8.5,
          formaPago: 'EFECTIVO',
          nombre: 'Efectivo',
          metodoPago: PaymentMethod(
            id: 3,
            formaPago: 'EFECTIVO',
            nombre: 'Efectivo',
          ),
        ),
      ],
    );

    final json = ticket.toJson();

    expect(json['propina'], 8.5);
    expect(json['mozoResponsable']['id'], 12);
    expect(json['pagosPropina'], hasLength(1));
    expect(json['pagosPropina'][0]['monto'], 8.5);
  });

  test('deserializa propina, responsable y pagos desde el backend', () {
    final ticket = Ticket.fromJson({
      'propina': 4,
      'mozoResponsable': {'id': 7, 'nombreCompleto': 'Luis Mesero'},
      'pagosPropina': [
        {
          'monto': 4,
          'montoPagado': 4,
          'formaPago': 'EFECTIVO',
          'metodoPago': {'id': 1, 'formaPago': 'EFECTIVO'},
        },
      ],
    });

    expect(ticket.propina, 4);
    expect(ticket.mozoResponsable?.id, 7);
    expect(ticket.pagosPropina?.single.monto, 4);
  });
}
