import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';

void main() {
  test('el vencimiento puede borrarse y viaja nulo en el payload', () {
    final ticket = Ticket(
      fechaVencimiento: '2026-10-24',
      fechaVencimientoDate: DateTime(2026, 10, 24),
    );
    final cleared = ticket.copyWith(
      fechaVencimiento: null,
      fechaVencimientoDate: null,
    );
    expect(cleared.toJson()['fechaVencimiento'], isNull);
    expect(cleared.toJson()['fechaVencimientoDate'], isNull);
    expect(ticket.copyWith(serie: 'B001').fechaVencimiento, '2026-10-24');
    expect(
      ticket.copyWith(serie: 'B001').fechaVencimientoDate,
      DateTime(2026, 10, 24),
    );
  });
}
