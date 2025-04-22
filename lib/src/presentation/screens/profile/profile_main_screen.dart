import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/screens/profile/profile_section/edit_profile_section.dart';
import 'package:teki_app/src/presentation/screens/profile/profile_section/profile_info_row.dart';
import 'package:teki_app/src/utils/contstants.dart';

class ProfileMainScreen extends StatefulWidget {
  const ProfileMainScreen({super.key});

  @override
  State<ProfileMainScreen> createState() => _ProfileMainScreenState();
}

class _ProfileMainScreenState extends State<ProfileMainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4D7CEB), Colors.white],
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 50),
                    const Center(
                      child: CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.transparent,
                        backgroundImage:
                            AssetImage("assets/images/avatar/avatar.png"),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            "Shane Watson",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              textStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                  color: Colors.white),
                            ),
                          ),
                          Text(
                            "Admin User",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              textStyle: const TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Card(
                      margin: EdgeInsets.zero,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 16,
                          left: 16,
                          right: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Account Info",
                              style: GoogleFonts.inter(
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const ProfileInfoRow(
                              iconPath:
                                  "assets/icons/icon_svg/profile_name.svg",
                              label: "Name",
                              value: "Shane Watson",
                            ),
                            const ProfileInfoRow(
                              iconPath:
                                  "assets/icons/icon_svg/profile_phone.svg",
                              label: "Phone",
                              value: "+02 259 857 654",
                            ),
                            const ProfileInfoRow(
                              iconPath:
                                  "assets/icons/icon_svg/profile_email.svg",
                              label: "Email",
                              value: "shane@example.com",
                            ),
                            const ProfileInfoRow(
                              iconPath:
                                  "assets/icons/icon_svg/profile_gender.svg",
                              label: "Gender",
                              value: "Male",
                            ),
                            const ProfileInfoRow(
                              iconPath:
                                  "assets/icons/icon_svg/profile_role.svg",
                              label: "Role",
                              value: "Admin",
                            ),
                            const ProfileInfoRow(
                              iconPath:
                                  "assets/icons/icon_svg/profile_company.svg",
                              label: "Company",
                              value: "teki_app",
                            ),
                            const ProfileInfoRow(
                              iconPath:
                                  "assets/icons/icon_svg/profile_address.svg",
                              label: "Address",
                              value: "5874 Street Park, New York, USA",
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.38,
                        child: ElevatedButton(
                          onPressed: () {
                            buildShowModalBottomSheet(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            backgroundColor: ColorSchema.primaryColor,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                "assets/icons/icon_svg/edit_icon.svg",
                                color: Colors.white70,
                                width: 15,
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              Text(
                                "Edit Profile",
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Positioned(
                top: 30,
                child: IconButton(
                  onPressed: () {
                    Get.back();
                  },
                  icon: const Icon(Icons.keyboard_arrow_left),
                  color: Colors.white,
                  iconSize: 30,
                ))
          ],
        ),
      ),
    );
  }

  void buildShowModalBottomSheet(BuildContext context) {
    showModalBottomSheet(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        isScrollControlled: true,
        context: context,
        builder: (_) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.9,
            child: const EditProfileSection(),
          );
        });
  }
}
