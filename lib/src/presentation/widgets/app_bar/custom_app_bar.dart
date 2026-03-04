import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/utils/contstants.dart';

class CustomAppBar extends StatelessWidget {
  final String navigateName;
  final String? navigateRoute;
  final String? subtitle;

  const CustomAppBar({
    super.key,
    required this.navigateName,
    this.navigateRoute,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      surfaceTintColor: Colors.white,
      backgroundColor: ColorSchema.primaryColor,
      centerTitle: true,
      title: subtitle != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  navigateName,
                  style: GoogleFonts.raleway(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle!,
                  style: GoogleFonts.raleway(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            )
          : Text(
              navigateName,
              style: GoogleFonts.raleway(fontWeight: FontWeight.w500, color: Colors.white),
            ),
      automaticallyImplyLeading: false,
      leading: IconButton(
          onPressed: () {
            if (navigateRoute == null) {
              Get.back();
              return;
            }
            Get.offAllNamed(navigateRoute!);
          },
          icon: const Icon(
            color: Colors.white,
            Icons.chevron_left,
            size: 30,
          )),
    );
  }
}
