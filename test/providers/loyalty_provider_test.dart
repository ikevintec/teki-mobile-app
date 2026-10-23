import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/company_summary.dart';
import 'package:teki_app/src/data/models/teki_model/config.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_card.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/loyalty/loyalty_provider.dart';
import '../support/loyalty_fixture.dart';

class _Delayed extends DemoLoyaltyRepository {
  final requests = <Completer<List<LoyaltyCard>>>[];
  final tokens = <CancelToken>[];
  @override
  Future<List<LoyaltyCard>> getCards({CancelToken? cancelToken}) {
    final pending = Completer<List<LoyaltyCard>>();
    requests.add(pending);
    tokens.add(cancelToken!);
    return pending.future;
  }
}

void main() {
  test('configuración persiste fidelización independientemente de envases', () {
    for (final containers in [false, true]) {
      final config = ConfigCompany.fromJson({
        'permitirFidelizacion': true,
        'permitirRetornoEnvase': containers,
      });
      expect(
        ConfigCompany.fromJson(config.toJson()).permitirFidelizacion,
        true,
      );
      expect(config.permitirRetornoEnvase, containers);
    }
    expect(ConfigCompany.fromJson({}).permitirFidelizacion, false);
  });

  test('consulta requiere flag y permiso de lectura, no de edición', () {
    expect(canViewLoyalty(loyaltySession()), true);
    expect(
      canViewLoyalty(loyaltySession(enabled: false, containers: true)),
      false,
    );
    expect(
      canViewLoyalty(loyaltySession(roles: ['LOYALTI_CONFIG_EDITAR'])),
      false,
    );
    expect(canViewLoyalty(loyaltySession(roles: ['SUPER_USUARIO'])), true);
    expect(
      canViewLoyalty(
        loyaltySession().copyWith(companySelected: Companysummary(id: 2)),
      ),
      false,
    );
  });

  for (final session in [
    loyaltySession(enabled: false),
    loyaltySession(roles: []),
  ]) {
    test('sin acceso no se consultan listado ni detalle', () async {
      final repo = DemoLoyaltyRepository();
      final container = ProviderContainer(
        overrides: [
          sesionProvider.overrideWith((ref) => LoyaltySessionNotifier(session)),
          loyaltyRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      expect(await container.read(loyaltyCardsProvider.future), isEmpty);
      expect(
        await container.read(
          loyaltyCardProvider((companyId: 1, cardId: 1)).future,
        ),
        null,
      );
      expect(repo.listCalls, 0);
      expect(repo.detailCalls, isEmpty);
    });
  }

  test('listado conserva todas las activas y excluye las inactivas', () async {
    final repo = DemoLoyaltyRepository(
      cards: [
        demoCard,
        secondCard,
        const LoyaltyCard(id: 3, nombre: 'Pausada'),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        sesionProvider.overrideWith(
          (ref) => LoyaltySessionNotifier(loyaltySession()),
        ),
        loyaltyRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    expect(
      (await container.read(loyaltyCardsProvider.future)).map((c) => c.id),
      [1, 2],
    );
  });

  test(
    'cambiar empresa cancela consulta y descarta la respuesta anterior',
    () async {
      final session = LoyaltySessionNotifier(loyaltySession());
      final repo = _Delayed();
      final container = ProviderContainer(
        overrides: [
          sesionProvider.overrideWith((ref) => session),
          loyaltyRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(loyaltyCardsProvider, (_, _) {});
      addTearDown(subscription.close);
      await Future<void>.delayed(Duration.zero);
      session.replace(loyaltySession(companyId: 2));
      await Future<void>.delayed(Duration.zero);
      expect(repo.tokens.first.isCancelled, true);
      repo.requests.last.complete([secondCard]);
      await container.read(loyaltyCardsProvider.future);
      repo.requests.first.complete([demoCard]);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(loyaltyCardsProvider).requireValue.single.id, 2);
      expect(
        await container.read(
          loyaltyCardProvider((companyId: 1, cardId: 1)).future,
        ),
        null,
      );
      expect(repo.detailCalls, isEmpty);
    },
  );

  test(
    'cerrar pantalla cancela la solicitud sin escribir en providers destruidos',
    () async {
      final repo = _Delayed();
      final container = ProviderContainer(
        overrides: [
          sesionProvider.overrideWith(
            (ref) => LoyaltySessionNotifier(loyaltySession()),
          ),
          loyaltyRepositoryProvider.overrideWithValue(repo),
        ],
      );
      final subscription = container.listen(loyaltyCardsProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      subscription.close();
      container.dispose();
      expect(repo.tokens.single.isCancelled, true);
      repo.requests.single.complete([demoCard]);
      await Future<void>.delayed(Duration.zero);
    },
  );
}
