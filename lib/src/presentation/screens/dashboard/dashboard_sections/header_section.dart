import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/providers/auth/login.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/contstants.dart';

class DashboardHeaderSection extends ConsumerWidget {
  final Function openDrawer;

  const DashboardHeaderSection({super.key, required this.openDrawer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final userName = user?.name ?? "User Name";
    final cargo = user?.cargo ?? "User Cargo";
    final username = user?.username ?? "User Username";
    final avatarUrl = user?.avatarUrl;
    final sizeAvatarImage = 48.0;
    return Container(
        color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.only(
          top: 0,
          left: 20,
          right: 16,
          bottom: 15,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: () {
                    openDrawer();
                  },
                  child: ClipOval(
                    child: avatarUrl != null && avatarUrl.isNotEmpty
                        ? Image.network(
                            avatarUrl,
                            width: sizeAvatarImage,
                            height: sizeAvatarImage,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Image.asset(
                                "assets/images/avatar/user_profile.png",
                                width: sizeAvatarImage,
                                height: sizeAvatarImage,
                                fit: BoxFit.cover,
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                "assets/images/avatar/user_profile.png",
                                width: sizeAvatarImage,
                                height: sizeAvatarImage,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : Image.asset(
                            "assets/images/avatar/user_profile.png",
                            width: sizeAvatarImage,
                            height: sizeAvatarImage,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(
                  width: 15,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.raleway(
                          textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                    Text(
                      '$username ($cargo)',
                      style: GoogleFonts.nunito(
                          textStyle: const TextStyle(
                              color: Colors.white, fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
            InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: () {
                Get.toNamed(AppRoutes.settings);
              },
              child: Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: Colors.white),
                child: const Icon(
                  Icons.tune,
                  color: ColorSchema.primaryColor,
                  size: 22,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
