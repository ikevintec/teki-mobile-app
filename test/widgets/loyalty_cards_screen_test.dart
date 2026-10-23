import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_card.dart';
import 'package:teki_app/src/presentation/screens/loyalty/loyalty_cards_screen.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/loyalty/loyalty_provider.dart';
import 'package:teki_app/src/shared/services/loyalty_link_service.dart';
import 'package:teki_app/src/shared/services/loyalty_share_service.dart';
import '../support/loyalty_fixture.dart';

class _Share extends LoyaltyShareService {
  String? copied;
  String? shared;
  Rect? origin;
  bool fail = false;
  @override
  Future<void> copy(String url) async {
    copied = url;
  }

  @override
  Future<void> share(String message, Rect anchor) async {
    if (fail) throw Exception('unavailable');
    shared = message;
    origin = anchor;
  }
}

void main() {
  Future<void> mount(
    WidgetTester tester, {
    DemoLoyaltyRepository? repo,
    _Share? share,
    Widget screen = const LoyaltyCardsScreen(),
    LoyaltySessionNotifier? session,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sesionProvider.overrideWith(
            (ref) => session ?? LoyaltySessionNotifier(loyaltySession()),
          ),
          loyaltyRepositoryProvider.overrideWithValue(
            repo ?? DemoLoyaltyRepository(),
          ),
          loyaltyLinkServiceProvider.overrideWithValue(
            const LoyaltyLinkService('https://app.teki.pe'),
          ),
          if (share != null)
            loyaltyShareServiceProvider.overrideWithValue(share),
        ],
        child: MaterialApp(
          theme: ThemeData(colorSchemeSeed: const Color(0xFF2C6AE5)),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: screen,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lista, detalle y QR de la segunda tarjeta conservan el enlace', (
    tester,
  ) async {
    final share = _Share();
    await mount(tester, share: share);
    await tester.tap(find.text('Mostrar QR').last);
    await tester.pumpAndSettle();
    const expectedUrl = 'https://app.teki.pe/fidelizacion/puntos-demo';
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text(expectedUrl), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Copiar enlace'),
      180,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Copiar enlace'));
    await tester.pumpAndSettle();
    expect(share.copied, expectedUrl);
    await tester.tap(find.text('Compartir enlace'));
    await tester.pumpAndSettle();
    expect(share.shared, endsWith(expectedUrl));
    expect(share.origin!.width, greaterThan(0));
    expect(find.text('Enviado'), findsNothing);
    expect(tester.takeException(), null);
  });

  testWidgets('sin acceso incluso navegación directa no hace solicitudes', (
    tester,
  ) async {
    final repo = DemoLoyaltyRepository();
    await mount(
      tester,
      repo: repo,
      session: LoyaltySessionNotifier(loyaltySession(enabled: false)),
    );
    expect(repo.listCalls, 0);
    expect(find.byType(QrImageView), findsNothing);
    expect(find.textContaining('no disponibles'), findsOneWidget);
  });

  testWidgets('vacío y error con reintento', (tester) async {
    final repo = DemoLoyaltyRepository()..failure = Exception('Sin conexión');
    await mount(tester, repo: repo);
    expect(find.text('Sin conexión'), findsOneWidget);
    repo.failure = null;
    repo.cards = [];
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Todavía no tienes tarjetas activas'),
      findsOneWidget,
    );
    expect(repo.listCalls, 2);
  });

  for (final inactive in [false, true]) {
    testWidgets('detalle no invita con tarjeta inactiva=$inactive o sin slug', (
      tester,
    ) async {
      await mount(
        tester,
        repo: DemoLoyaltyRepository(
          cards: [
            LoyaltyCard(
              id: 1,
              nombre: 'No disponible',
              activo: !inactive,
              slug: inactive ? 'valid' : null,
            ),
          ],
        ),
        screen: const LoyaltyCardScreen(
          companyId: 1,
          cardId: 1,
          qrInitially: true,
        ),
      );
      expect(find.byType(QrImageView), findsNothing);
      expect(find.text('Compartir enlace'), findsNothing);
    });
  }

  testWidgets(
    'cambiar empresa oculta el QR abierto y no consulta el ID anterior',
    (tester) async {
      final session = LoyaltySessionNotifier(loyaltySession());
      final repo = DemoLoyaltyRepository();
      await mount(
        tester,
        session: session,
        repo: repo,
        screen: const LoyaltyCardScreen(
          companyId: 1,
          cardId: 1,
          qrInitially: true,
        ),
      );
      expect(find.byType(QrImageView), findsOneWidget);
      session.replace(loyaltySession(companyId: 2));
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsNothing);
      expect(repo.detailCalls, [1]);
    },
  );

  testWidgets(
    'pantalla pequeña con texto ampliado mantiene QR y acciones sin overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(
        tester,
        textScale: 2,
        screen: const LoyaltyCardScreen(
          companyId: 1,
          cardId: 1,
          qrInitially: true,
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Copiar enlace'),
        180,
        scrollable: find
            .descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), null);
    },
  );

  testWidgets('fallo al compartir permite reintentar y no confirma un envío', (
    tester,
  ) async {
    final share = _Share()..fail = true;
    await mount(
      tester,
      share: share,
      screen: const LoyaltyCardScreen(companyId: 1, cardId: 1),
    );
    await tester.ensureVisible(find.text('Compartir enlace'));
    await tester.tap(find.text('Compartir enlace'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No se pudo abrir'), findsOneWidget);
    share.fail = false;
    await tester.tap(find.text('Compartir enlace'));
    await tester.pumpAndSettle();
    expect(share.shared, isNotNull);
    expect(find.text('Enviado'), findsNothing);
  });
}
