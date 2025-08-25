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
    return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
            ColorSchema.primaryColor,
            ColorSchema.primaryColor,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          top: 30,
          left: 10,
          right: 16,
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
                  child: avatarUrl == null
                      ? Image.asset(
                          "assets/images/avatar/user_profile.png",
                          width: 60,
                        )
                      : ClipOval(
                          child: Image.network(
                            avatarUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.error);
                            },
                          ),
                        ),
                ),
                const SizedBox(
                  width: 8,
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
              child: Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: Colors.white),
                    child: const Icon(
                      Icons.tune,
                      color: ColorSchema.primaryColor,
                      size: 26,
                    ),
                  ),
                  // Positioned(
                  //     right: 14,
                  //     top: 14,
                  //     child: Container(
                  //       width: 5,
                  //       height: 5,
                  //       decoration: BoxDecoration(
                  //           borderRadius: BorderRadius.circular(50),
                  //           color: Colors.red),
                  //     ))
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
