import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_card.dart';
import 'package:teki_app/src/shared/services/loyalty_link_service.dart';
import '../support/loyalty_fixture.dart';

void main() {
  test('QR y mensaje conservan el slug elegido sin credenciales', () {
    const links = LoyaltyLinkService('https://app.teki.pe/');
    final first = links.registrationUrl(demoCard)!;
    final second = links.registrationUrl(secondCard)!;
    expect(first, 'https://app.teki.pe/fidelizacion/programa-demo');
    expect(second, 'https://app.teki.pe/fidelizacion/puntos-demo');
    expect(first, isNot(second));
    expect(links.shareMessage(demoCard, 'Mi negocio', first), endsWith(first));
    expect(Uri.parse(first).hasQuery, false);
  });
  test('sin tarjeta activa o slug válido no hay invitación', () {
    const links = LoyaltyLinkService('https://app.teki.pe');
    for (final slug in [
      null,
      '',
      '../admin',
      'slug?jwt=token',
      'a/b',
      'con espacios',
    ]) {
      expect(
        links.registrationUrl(
          LoyaltyCard(id: 1, nombre: 'A', activo: true, slug: slug),
        ),
        null,
      );
    }
    expect(
      links.registrationUrl(
        const LoyaltyCard(id: 1, nombre: 'A', slug: 'valid'),
      ),
      null,
    );
  });
  test('rechaza bases vacías, API, localhost y URLs con credenciales', () {
    for (final base in [
      '',
      '/api',
      'http://localhost:4200',
      'http://127.0.0.1',
      'https://api.teki.pe/api',
      'https://user:pass@app.teki.pe',
      'https://app.teki.pe?token=secret',
      'javascript:alert(1)',
      'https://app.teki.pe/#/admin',
    ]) {
      expect(
        LoyaltyLinkService(base).registrationUrl(demoCard),
        null,
        reason: base,
      );
    }
    expect(
      const LoyaltyLinkService(
        'http://192.168.1.10:4200',
      ).registrationUrl(demoCard),
      'http://192.168.1.10:4200/fidelizacion/programa-demo',
    );
  });
}
