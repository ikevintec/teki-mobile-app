// Vista reproducible de P1 con datos sintéticos. No consulta ni modifica cuentas.
// flutter run -t test/previews/loyalty_preview.dart -d <simulador>
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/presentation/screens/loyalty/loyalty_cards_screen.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/loyalty/loyalty_provider.dart';
import 'package:teki_app/src/shared/services/loyalty_link_service.dart';
import '../support/loyalty_fixture.dart';

void main() {
  if (kReleaseMode) throw StateError('Esta vista es solo para pruebas.');
  runApp(
    ProviderScope(
      overrides: [
        sesionProvider.overrideWith(
          (ref) => LoyaltySessionNotifier(loyaltySession()),
        ),
        loyaltyRepositoryProvider.overrideWithValue(DemoLoyaltyRepository()),
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
