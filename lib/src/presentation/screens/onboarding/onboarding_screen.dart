import 'package:flutter/material.dart';
import 'package:flutter_onboarding_slider/flutter_onboarding_slider.dart';
import 'package:get/route_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/contstants.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: OnBoardingSlider(
          pageBackgroundColor: Colors.white,
          finishButtonText: "Iniciar sesion",
          onFinish: () {
            Get.toNamed(AppRoutes.login);
          },
          finishButtonStyle: const FinishButtonStyle(
            backgroundColor: ColorSchema.primaryColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(5.0))),
          ),
          trailing: Container(
            color: Colors.white,
          ),
          skipTextButton: Text(
            "Saltar >",
            style: GoogleFonts.raleway(
                textStyle: const TextStyle(
                    fontSize: 16,
                    color: ColorSchema.primaryColor,
                    fontWeight: FontWeight.w700)),
          ),
          controllerColor: ColorSchema.primaryColor,
          totalPage: 3,
          headerBackgroundColor: Colors.white,
          background: [
            Padding(
              padding: EdgeInsets.only(top: screenHeight * 0.1),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Image.asset(
                  'assets/images/onboarding/slide-1.png',
                  height: MediaQuery.of(context).size.height * 0.35,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: screenHeight * 0.1),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Image.asset(
                  'assets/images/onboarding/slide-2.png',
                  height: MediaQuery.of(context).size.height * 0.35,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: screenHeight * 0.1),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Image.asset(
                  'assets/images/onboarding/slide-3.png',
                  height: MediaQuery.of(context).size.height * 0.35,
                ),
              ),
            ),
          ],
          speed: 2,
          pageBodies: [
            Container(
              alignment: Alignment.center,
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    height: screenHeight * 0.5,
                  ),
                  Text(
                    'Accesibilidad y seguridad',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.raleway(
                        textStyle: TextStyle(
                      color: ColorSchema.titleTextColor,
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                    )),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    'Teki app es un sistema de punto de venta que permite a los usuarios acceder de forma segura a su información desde cualquier lugar y en cualquier momento.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                        textStyle: TextStyle(
                            color: ColorSchema.subTitleTextColor,
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w400)),
                  ),
                ],
              ),
            ),
            Container(
              alignment: Alignment.center,
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    height: screenHeight * 0.5,
                  ),
                  Text(
                    'Facil de usar',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.raleway(
                        textStyle: TextStyle(
                      color: ColorSchema.titleTextColor,
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                    )),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    'Ofrecemos intuitivas y sencillas herramientas para que puedas gestionar tu negocio de manera eficiente.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                        textStyle: TextStyle(
                            color: ColorSchema.subTitleTextColor,
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w400)),
                  ),
                ],
              ),
            ),
            Container(
              alignment: Alignment.center,
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: screenHeight * 0.5,
                  ),
                  Text(
                    'Todo en un solo lugar',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.raleway(
                        textStyle: TextStyle(
                            color: ColorSchema.titleTextColor,
                            fontSize: screenWidth * 0.06,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    'Con Teki app puedes gestionar tu inventario, ventas y reportes desde una sola plataforma.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                        textStyle: TextStyle(
                            color: ColorSchema.subTitleTextColor,
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w400)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
