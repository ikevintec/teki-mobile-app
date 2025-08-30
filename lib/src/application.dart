import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/main.dart'; // Importa el routeObserver global
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:teki_app/src/presentation/widgets/keyboard_dismisser.dart';

class Application extends StatelessWidget {
  const Application({super.key});

  @override
  Widget build(BuildContext context) {
    return KeyboardDismisser(
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
      ),
    );
  }
}
