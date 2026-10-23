import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_card.dart';
import 'package:teki_app/src/data/repositories/loyalty_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/loyalty_repository.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/shared/services/loyalty_link_service.dart';
import 'package:teki_app/src/utils/constants.dart';

/// El backend toma la empresa del JWT. No consultar otra empresa seleccionada
/// usando el token anterior, aunque comparta permisos o configuración.
bool canViewLoyalty(SesionState session) =>
    session.config?.permitirFidelizacion == true &&
    (session.hasPermission('LOYALTI_CONFIG_VER') ||
        session.hasPermission('SUPER_USUARIO')) &&
    session.companySelected?.id != null &&
    session.companySelected?.id == session.login.user?.empresa?.id &&
    session.login.accessToken?.isNotEmpty == true;

final loyaltyScopeProvider = Provider((ref) {
  final session = ref.watch(sesionProvider);
  if (!canViewLoyalty(session)) return null;
  return (
    companyId: session.companySelected!.id!,
    userId: session.login.user?.id,
    token: session.login.accessToken,
  );
});

final loyaltyRepositoryProvider = Provider<LoyaltyRepository>(
  (ref) => LoyaltyRepositoryImpl(),
);

final loyaltyLinkServiceProvider = Provider(
  (ref) => LoyaltyLinkService(Environment.loyaltyPublicBaseUrl),
);

final loyaltyCardsProvider = FutureProvider.autoDispose<List<LoyaltyCard>>((
  ref,
) async {
  if (ref.watch(loyaltyScopeProvider) == null) return const [];
  final cancel = CancelToken();
  ref.onDispose(cancel.cancel);
  final cards = await ref
      .watch(loyaltyRepositoryProvider)
      .getCards(cancelToken: cancel);
  return cards.where((card) => card.activo).toList();
});

final loyaltyCardProvider = FutureProvider.autoDispose
    .family<LoyaltyCard?, ({int companyId, int cardId})>((ref, key) async {
      final scope = ref.watch(loyaltyScopeProvider);
      if (scope == null || scope.companyId != key.companyId) return null;
      final cancel = CancelToken();
      ref.onDispose(cancel.cancel);
      return ref
          .watch(loyaltyRepositoryProvider)
          .getCard(key.cardId, cancelToken: cancel);
    });
