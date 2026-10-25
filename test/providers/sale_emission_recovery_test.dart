import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
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
