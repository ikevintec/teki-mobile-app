import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/payment_detail.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/domain/errors/ticket_emission_exception.dart';
import 'package:teki_app/src/domain/repositories/quotation_repository.dart';
import 'package:teki_app/src/domain/repositories/tickets_sale_repository.dart';
import 'package:teki_app/src/providers/auth/login.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import '../support/envase_sale_fixture.dart';

class _Ref extends SaleTestRef {
  @override
  T read<T>(ProviderListenable<T> provider) {
    if (identical(provider, authStateProvider))
      return AuthState(isLoggedIn: true) as T;
    return super.read(provider);
  }
}

class _Tickets implements TicketsSaleRepository {
  int creates = 0;
  Map<String, dynamic>? filters;
  @override
  Future<Ticket> createTicket(Ticket ticket) async {
    creates++;
    throw const TicketEmissionException('Respuesta perdida');
  }

  @override
  Future<List<Ticket>> getComprobantes(Map<String, dynamic> params) async {
    filters = params;
    return [Ticket(id: 42, serie: 'B001', numero: 99)];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Quotations implements QuotationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('propina y vuelto sobreviven al editor y a su payload de emisión', () {
    final notifier = TicketNotifier(
      ref: _Ref(),
      ticketsSaleRepository: _Tickets(),
      quotationRepository: _Quotations(),
      notifyError: (_) {},
    );
    addTearDown(notifier.dispose);
    final ticket = Ticket.fromJson(
      Ticket(
        serie: 'N001',
        tipoComprobante: 'NV',
        propina: 5,
        mozoResponsable: User(id: 3),
        pagosPropina: [
          PaymentDetail(
            formaPago: 'EFECTIVO',
            monto: 5,
            montoPagado: 10,
            cambio: 5,
          ),
        ],
      ).toJson(),
    );
    notifier.updateTicket(ticket.copyWith(totalVenta: 19.43));
    final payload = notifier.getTicketPayload();
    final numeric = Ticket.fromJson({'totalVenta': 20, 'efectivo': 30, 'cambio': 10, 'propina': 2});
    expect(numeric.totalVenta, 20.0);
    expect(numeric.efectivo, 30.0);
    expect(numeric.cambio, 10.0);
    expect(numeric.propina, 2.0);
    expect(payload.propina, 5);
    expect(payload.mozoResponsable?.id, 3);
    expect(payload.pagosPropina?.single.monto, 5);
    expect(payload.pagosPropina?.single.montoPagado, 10);
    expect(payload.pagosPropina?.single.cambio, 5);
  });
  test(
    'una respuesta desconocida conserva la venta y bloquea otro POST hasta revisión explícita',
    () async {
      final repository = _Tickets();
      final messages = <String>[];
      final notifier = TicketNotifier(
        ref: _Ref(),
        ticketsSaleRepository: repository,
        quotationRepository: _Quotations(),
        notifyError: messages.add,
      );
      addTearDown(notifier.dispose);
      notifier.updateTicket(
        Ticket(serie: 'B001', tipoComprobante: '03', totalVenta: 100),
      );
      expect(await notifier.proceessTicket(), isNull);
      expect(await notifier.proceessTicket(), isNull);
      expect(repository.creates, 1);
      notifier.resetTicket();
      expect(notifier.state.pendingEmission?.totalVenta, 100);
      expect(notifier.state.ticket.serie, 'B001');
      final results = await notifier.verifyPendingEmission();
      expect(results.single.id, 42);
      expect(repository.filters?['filtroSerie'], 'B001');
      expect(repository.filters?['filtroTipoComprobante'], ['03']);
      expect(repository.creates, 1);
      notifier.confirmEmissionNotRegistered();
      expect(notifier.state.pendingEmission, isNull);
      expect(notifier.state.ticket.totalVenta, 100);
      await notifier.proceessTicket();
      expect(repository.creates, 2);
    },
  );
  test(
    'limpiar vencimiento elimina los dos valores del ticket y su payload',
    () {
      final notifier = TicketNotifier(
        ref: _Ref(),
        ticketsSaleRepository: _Tickets(),
        quotationRepository: _Quotations(),
        notifyError: (_) {},
      );
      addTearDown(notifier.dispose);
      notifier.setFechaVencimiento(DateTime(2026, 10, 24));
      notifier.setFechaVencimiento(null);
      expect(notifier.getTicketPayload().fechaVencimiento, isNull);
      expect(notifier.getTicketPayload().fechaVencimientoDate, isNull);
    },
  );
}
