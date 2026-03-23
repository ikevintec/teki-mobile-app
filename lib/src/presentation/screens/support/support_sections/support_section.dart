import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class SupportSection extends StatelessWidget {
  const SupportSection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double fontSizeTitle = screenWidth * 0.04;
    double fontSizeDesc = screenWidth * 0.032;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.055),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildBodySection(
                  screenWidth,
                  fontSizeTitle,
                  fontSizeDesc,
                  "assets/icons/icon_svg/get_started_icon.svg",
                  "Unlocking a world of possibilities",
                  "Get Started"),
              buildBodySection(
                  screenWidth,
                  fontSizeTitle,
                  fontSizeDesc,
                  "assets/icons/icon_svg/account_icon.svg",
                  "Manage your account efficiently",
                  "Accounts"),
            ],
          ),
          SizedBox(
            height: screenHeight * 0.025,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildBodySection(
                  screenWidth,
                  fontSizeTitle,
                  fontSizeDesc,
                  "assets/icons/icon_svg/subscription_icon.svg",
                  "Subscribe now to unlock premium",
                  "Subscription"),
              buildBodySection(
                  screenWidth,
                  fontSizeTitle,
                  fontSizeDesc,
                  "assets/icons/icon_svg/help_icon.svg",
                  "Our dedicated support team is here to help",
                  "Help"),
            ],
          )
        ],
      ),
    );
  }

  Container buildBodySection(double screenWidth, double fontSizeTitle,
      double fontSizeDesc, String icon, String desc, String title) {
    return Container(
      padding: const EdgeInsets.all(10),
      width: screenWidth * 0.42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: screenWidth * 0.17,
            height: screenWidth * 0.17,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(screenWidth * 0.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: SvgPicture.asset(
                icon,
                width: screenWidth * 0.1,
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            title,
            style: GoogleFonts.raleway(
              fontWeight: FontWeight.w700,
              fontSize: fontSizeTitle,
            ),
          ),
          const SizedBox(
            height: 2,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Text(
              desc,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: Colors.black87,
                fontSize: fontSizeDesc,
              ),
            ),
          )
        ],
      ),
    );
  }
}
