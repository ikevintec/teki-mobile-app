import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/providers/auth/login.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/contstants.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAuth();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();

    Timer(const Duration(seconds: 5), () {
      Navigator.pushNamed(context, AppRoutes.onboarding);
    });
  }

  void initAuth() async {
    await ref.read(authStateProvider.notifier).checkAuthStatus();
    // La navegación se hace dentro del propio checkAuthStatus() usando Get.offAllNamed()
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.maxFinite,
        // color: ColorSchema.primaryColor,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ColorSchema.primaryColor,
              Color.fromARGB(255, 24, 151, 255),
              // Color.fromARGB(255, 51, 53, 161)
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo
                  Expanded(
                    child: ScaleTransition(
                      scale: _animation,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: MediaQuery.of(context).size.width * 0.2,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                "assets/images/logo/logo-teki-solo.png",
                                width: 100,
                              ),
                              Text("Teki app",
                                  style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: ColorSchema.primaryColor)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Animated text
                  FadeTransition(
                    opacity: _animation,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          "Teki Solutions",
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          "V 1.0.2",
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
