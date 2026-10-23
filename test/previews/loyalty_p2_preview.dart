// Solo datos sintéticos; no consulta ni modifica cuentas.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/presentation/screens/loyalty/loyalty_cards_screen.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/loyalty/loyalty_provider.dart';
import 'package:teki_app/src/shared/services/loyalty_link_service.dart';
import '../support/loyalty_fixture.dart';
import '../support/loyalty_p2_fixture.dart';

void main() {
  if (kReleaseMode) throw StateError('Esta vista es solo para pruebas.');
  runApp(
    ProviderScope(
      overrides: [
        sesionProvider.overrideWith(
          (ref) => LoyaltySessionNotifier(loyaltySession(roles: p2Roles)),
        ),
        loyaltyRepositoryProvider.overrideWithValue(DemoLoyaltyP2Repository()),
        loyaltyLinkServiceProvider.overrideWithValue(
          const LoyaltyLinkService('https://example.com'),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) => Banner(
          message: 'DATOS SIMULADOS',
          location: BannerLocation.topEnd,
          child: child!,
        ),
        home: const LoyaltyCardsScreen(),
      ),
    ),
  );
}
