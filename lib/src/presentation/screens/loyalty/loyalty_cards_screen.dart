import 'package:teki_app/src/presentation/screens/loyalty/widgets/loyalty_shell.dart';
import 'package:teki_app/src/presentation/screens/loyalty/loyalty_customers_screen.dart';
import 'package:teki_app/src/providers/loyalty/loyalty_customers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_card.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/loyalty/loyalty_provider.dart';
import 'package:teki_app/src/shared/services/loyalty_share_service.dart';
import 'package:teki_app/src/utils/constants.dart';

class LoyaltyCardsScreen extends ConsumerWidget {
  const LoyaltyCardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(loyaltyScopeProvider);
    return LoyaltyScaffold(
      title: 'Tarjetas de fidelización',
      allowed: scope != null,
      child: scope == null
          ? const SizedBox.shrink()
          : ref
                .watch(loyaltyCardsProvider)
                .when(
                  skipLoadingOnRefresh: false,
                  skipLoadingOnReload: false,
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => LoyaltyMessage(
                    icon: Icons.cloud_off_outlined,
                    text: loyaltyErrorText(error),
                    retry: () => ref.invalidate(loyaltyCardsProvider),
                  ),
                  data: (cards) => RefreshIndicator(
                    onRefresh: () => ref.refresh(loyaltyCardsProvider.future),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      children: [
                        const Text(
                          'Invita a tus clientes',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Muestra el QR o comparte el enlace de una tarjeta para que puedan registrarse.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF535965),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (cards.isEmpty)
                          const LoyaltyMessage(
                            icon: Icons.loyalty_outlined,
                            text:
                                'Todavía no tienes tarjetas activas. Puedes configurarlas desde la web de Teki.',
                          ),
                        for (final card in cards)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CardRow(
                              card: card,
                              canInvite:
                                  ref
                                      .watch(loyaltyLinkServiceProvider)
                                      .registrationUrl(card) !=
                                  null,
                              onOpen: (qr) => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => LoyaltyCardScreen(
                                    companyId: scope.companyId,
                                    cardId: card.id,
                                    qrInitially: qr,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _CardRow extends StatelessWidget {
  final LoyaltyCard card;
  final bool canInvite;
  final void Function(bool qr) onOpen;
  const _CardRow({
    required this.card,
    required this.canInvite,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Logo(url: card.logoUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.nombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (card.tipo.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(card.tipo),
                      ),
                    if (card.principal)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Principal',
                          style: TextStyle(
                            color: ColorSchema.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (card.textoRecompensa?.trim().isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(card.textoRecompensa!),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              TextButton(
                onPressed: () => onOpen(false),
                child: const Text('Ver tarjeta'),
              ),
              OutlinedButton.icon(
                onPressed: canInvite ? () => onOpen(true) : null,
                icon: const Icon(Icons.qr_code),
                label: const Text('Mostrar QR'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class LoyaltyCardScreen extends ConsumerStatefulWidget {
  final int companyId;
  final int cardId;
  final bool qrInitially;
  const LoyaltyCardScreen({
    super.key,
    required this.companyId,
    required this.cardId,
    this.qrInitially = false,
  });

  @override
  ConsumerState<LoyaltyCardScreen> createState() => _LoyaltyCardScreenState();
}

class _LoyaltyCardScreenState extends ConsumerState<LoyaltyCardScreen> {
  late bool _showQr = widget.qrInitially;
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    final scope = ref.watch(loyaltyScopeProvider);
    final allowed = scope != null && scope.companyId == widget.companyId;
    final key = (companyId: widget.companyId, cardId: widget.cardId);
    return LoyaltyScaffold(
      title: _showQr ? 'Registro de tarjeta' : 'Detalle de tarjeta',
      allowed: allowed,
      child: !allowed
          ? const SizedBox.shrink()
          : ref
                .watch(loyaltyCardProvider(key))
                .when(
                  skipLoadingOnRefresh: false,
                  skipLoadingOnReload: false,
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => LoyaltyMessage(
                    icon: Icons.cloud_off_outlined,
                    text: loyaltyErrorText(error),
                    retry: () => ref.invalidate(loyaltyCardProvider(key)),
                  ),
                  data: (card) {
                    if (card == null) return const SizedBox.shrink();
                    final links = ref.watch(loyaltyLinkServiceProvider);
                    final url = links.registrationUrl(card);
                    final session = ref.watch(sesionProvider);
                    final company = session.companySelected;
                    final business =
                        [company?.nombreComercial, company?.razonSocial]
                            .whereType<String>()
                            .where((s) => s.trim().isNotEmpty && s != 'null')
                            .firstOrNull ??
                        'tu negocio';
                    return RefreshIndicator(
                      onRefresh: () =>
                          ref.refresh(loyaltyCardProvider(key).future),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        children: [
                          if (!_showQr) _Preview(card: card),
                          const SizedBox(height: 20),
                          Text(
                            card.nombre,
                            textAlign: _showQr
                                ? TextAlign.center
                                : TextAlign.start,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            business,
                            textAlign: _showQr
                                ? TextAlign.center
                                : TextAlign.start,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF535965),
                            ),
                          ),
                          if (!_showQr && card.tipo.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(card.tipo),
                            ),
                          if (!_showQr &&
                              card.textoRecompensa?.trim().isNotEmpty == true)
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Text(
                                card.textoRecompensa!,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          if (!_showQr && canViewLoyaltyCustomers(session)) ...[
                            const SizedBox(height: 20),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => LoyaltyCustomersScreen(
                                    companyId: widget.companyId,
                                    card: card,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.people_outline),
                              label: const Text('Clientes de esta tarjeta'),
                            ),
                          ],
                          const SizedBox(height: 24),
                          if (url == null)
                            LoyaltyMessage(
                              icon: Icons.info_outline,
                              text: !card.activo
                                  ? 'Esta tarjeta está inactiva y no permite nuevos registros.'
                                  : 'El registro de esta tarjeta no está disponible. Revísala desde la web de Teki.',
                            )
                          else ...[
                            if (_showQr) ...[
                              const Text(
                                'Escanea para obtener tu tarjeta',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 340,
                                  ),
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: QrImageView(
                                      key: const ValueKey(
                                        'loyalty-registration-qr',
                                      ),
                                      data: url,
                                      padding: const EdgeInsets.all(28),
                                      backgroundColor: Colors.white,
                                      semanticsLabel:
                                          'QR de registro de ${card.nombre}',
                                      errorCorrectionLevel:
                                          QrErrorCorrectLevel.M,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SelectableText(url, textAlign: TextAlign.center),
                              const SizedBox(height: 24),
                            ] else ...[
                              FilledButton.icon(
                                onPressed: () => setState(() => _showQr = true),
                                icon: const Icon(Icons.qr_code),
                                label: const Text('Mostrar QR'),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Builder(
                              builder: (buttonContext) => OutlinedButton.icon(
                                onPressed: _sharing
                                    ? null
                                    : () => _share(
                                        buttonContext,
                                        links.shareMessage(card, business, url),
                                      ),
                                icon: const Icon(Icons.ios_share),
                                label: Text(
                                  _sharing ? 'Abriendo…' : 'Compartir enlace',
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _copy(url),
                              icon: const Icon(Icons.copy_outlined),
                              label: const Text('Copiar enlace'),
                            ),
                            if (_showQr)
                              TextButton(
                                onPressed: () =>
                                    setState(() => _showQr = false),
                                child: const Text('Volver al detalle'),
                              ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _share(BuildContext buttonContext, String message) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final origin = box.localToGlobal(Offset.zero) & box.size;
    setState(() => _sharing = true);
    try {
      await ref.read(loyaltyShareServiceProvider).share(message, origin);
    } catch (_) {
      if (mounted) {
        _notice('No se pudo abrir el menú de compartir. Intenta nuevamente.');
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _copy(String url) async {
    try {
      await ref.read(loyaltyShareServiceProvider).copy(url);
      if (mounted) _notice('Enlace copiado');
    } catch (_) {
      if (mounted) _notice('No se pudo copiar el enlace. Intenta nuevamente.');
    }
  }

  void _notice(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _Preview extends StatelessWidget {
  final LoyaltyCard card;
  const _Preview({required this.card});

  @override
  Widget build(BuildContext context) {
    final hex = card.hexBackgroundColor?.replaceFirst('#', '');
    final value = hex != null && RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)
        ? int.tryParse('FF$hex', radix: 16)
        : null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 160,
        color: value == null ? ColorSchema.primaryColor : Color(value),
        child: card.heroImageUrl?.isNotEmpty == true
            ? Image.network(
                card.heroImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Center(child: _Logo(url: card.logoUrl, size: 72)),
              )
            : Center(child: _Logo(url: card.logoUrl, size: 72)),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final String? url;
  final double size;
  const _Logo({this.url, this.size = 52});

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      Icons.loyalty_outlined,
      size: size * .55,
      color: ColorSchema.primaryColor,
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: url?.isNotEmpty == true
          ? Image.network(
              url!,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => fallback,
            )
          : fallback,
    );
  }
}
