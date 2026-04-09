import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toastification/toastification.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/main.dart'; // Importa el routeObserver global
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:teki_app/src/presentation/widgets/keyboard_dismisser.dart';

class Application extends StatelessWidget {
  const Application({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: KeyboardDismisser(
      child: GetMaterialApp(
      title: "teki_app",
      locale: const Locale('es'), // tu idioma deseado
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      initialRoute: AppRoutes.splashScreen,
      getPages: AppRoutes.pages,
      builder: (context, child) {
        // Solo aplicar SafeArea en Android con navegación por botones.
        // La navegación por gestos reserva insets laterales (left/right > 0),
        // en botones esos insets son 0. En iOS no aplica.
        if (!Platform.isAndroid) return child!;
        final gestureInsets = MediaQuery.of(context).systemGestureInsets;
        final isGestureNav = gestureInsets.left > 0 || gestureInsets.right > 0;
        if (isGestureNav) return child!;
        return ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(top: false, child: child!),
        );
      },
      ),
      ),
    );
  }
}
