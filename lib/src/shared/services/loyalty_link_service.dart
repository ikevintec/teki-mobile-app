import 'package:teki_app/src/data/models/teki_model/loyalty_card.dart';

/// Única fuente del enlace: QR, portapapeles y compartir usan el mismo valor.
class LoyaltyLinkService {
  final String publicBaseUrl;
  const LoyaltyLinkService(this.publicBaseUrl);

  String? registrationUrl(LoyaltyCard card) {
    if (!card.activo ||
        card.slug == null ||
        !RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(card.slug!)) {
      return null;
    }
    final base = Uri.tryParse(publicBaseUrl.trim());
    if (base == null ||
        !base.hasAuthority ||
        base.host.isEmpty ||
        !['http', 'https'].contains(base.scheme) ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        base.host == 'localhost' ||
        base.host == '127.0.0.1' ||
        base.host == '::1' ||
        base.pathSegments.any((segment) => segment.toLowerCase() == 'api')) {
      return null;
    }
    final path = base.path.replaceFirst(RegExp(r'/+$'), '');
    return base.replace(path: '$path/fidelizacion/${card.slug}').toString();
  }

  String shareMessage(LoyaltyCard card, String business, String url) =>
      'Obtén tu tarjeta de $business y participa en ${card.nombre}: $url';
}
