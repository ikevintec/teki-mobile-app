import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/screens/ai_chat/widgets/ai_orb_button.dart';
import 'package:teki_app/src/providers/auth/login.dart';
import 'package:teki_app/src/routes/app_routes.dart';

class DashboardHeaderSection extends ConsumerWidget {
  final Function openDrawer;

  /// Abre el asistente Teki AI; null oculta el orbe (solo el tab Inicio lo pasa).
  final VoidCallback? onAiTap;

  const DashboardHeaderSection({super.key, required this.openDrawer, this.onAiTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final userName = user?.name ?? 'Usuario';
    final cargo = user?.cargo ?? '';
    final username = user?.username ?? '';
    final avatarUrl = user?.avatarUrl;
    const avatarSize = 48.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          // ── Avatar con anillo ──────────────────────────────────────────
          GestureDetector(
            onTap: () => openDrawer(),
            child: Container(
              width: avatarSize + 6,
              height: avatarSize + 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 2.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: avatarUrl != null && avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          width: avatarSize,
                          height: avatarSize,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                                  ? child
                                  : Image.asset(
                                      'assets/images/avatar/user_profile.png',
                                      width: avatarSize,
                                      height: avatarSize,
                                      fit: BoxFit.cover,
                                    ),
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/images/avatar/user_profile.png',
                            width: avatarSize,
                            height: avatarSize,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          'assets/images/avatar/user_profile.png',
                          width: avatarSize,
                          height: avatarSize,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // ── Saludo + nombre ────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.raleway(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                if (username.isNotEmpty || cargo.isNotEmpty)
                  Text(
                    [if (username.isNotEmpty) username, if (cargo.isNotEmpty) cargo].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.65),
                      height: 1.2,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // ── Orbe del asistente Teki AI (solo lo pasa el tab Inicio) ────
          if (onAiTap != null) ...[
            AiOrbButton(onTap: onAiTap!, size: 40),
            const SizedBox(width: 10),
          ],

          // ── Botón ajustes ──────────────────────────────────────────────
          GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.settings),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
