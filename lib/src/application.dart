import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/routes/app_routes.dart';

class Application extends StatelessWidget {
  const Application({super.key});

  @override
  Widget build(BuildContext context) {

    return GetMaterialApp(
      title: "teki_app",
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splashScreen,
      getPages: AppRoutes.pages,
    );
  }
}
