import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/screens/profile/profile_section/profile_info_row.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/contstants.dart';

class ProfileMainScreen extends ConsumerStatefulWidget {
  const ProfileMainScreen({super.key});

  @override
  ConsumerState<ProfileMainScreen> createState() => _ProfileMainScreenState();
}

class _ProfileMainScreenState extends ConsumerState<ProfileMainScreen> {
  @override
  Widget build(BuildContext context) {
    final sesionState = ref.watch(sesionProvider);
    final user = sesionState.login.user;
    final company = sesionState.companySelected;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ColorSchema.primaryColor, Color.fromARGB(255, 135, 217, 255)],
          ),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 70),
                    Center(
                      child: CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.transparent,
                        child: ClipOval(
                          child: user?.avatarUrl?.isNotEmpty == true
                              ? Image.network(
                                  user!.avatarUrl!,
                                  width: 140,
                                  height: 140,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset(
                                    "assets/images/avatar/avatar.png",
                                    width: 140,
                                    height: 140,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Image.asset(
                                  "assets/images/avatar/avatar.png",
                                  width: 140,
                                  height: 140,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            user?.name ?? "Sin nombre",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              textStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                  color: Colors.white),
                            ),
                          ),
                          Text(
                            user?.cargo ?? "Usuario",
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
                              "Información de la Cuenta",
                              style: GoogleFonts.inter(
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ProfileInfoRow(
                              icon: Icons.person_outline,
                              label: "Nombre",
                              value: user?.name ?? "Sin nombre",
                            ),
                            ProfileInfoRow(
                              icon: Icons.phone_outlined,
                              label: "Teléfono",
                              value: company?.telefono ?? "Sin teléfono",
                            ),
                            ProfileInfoRow(
                              icon: Icons.email_outlined,
                              label: "Correo",
                              value: company?.email ?? "Sin email",
                            ),
                            ProfileInfoRow(
                              icon: Icons.account_circle_outlined,
                              label: "Usuario",
                              value: user?.username ?? "Sin usuario",
                            ),
                            ProfileInfoRow(
                              icon: Icons.badge_outlined,
                              label: "Rol",
                              value: user?.cargo ?? "Sin rol",
                            ),
                            ProfileInfoRow(
                              icon: Icons.business_outlined,
                              label: "Compañia",
                              value: company?.razonSocial ?? "Sin empresa",
                            ),
                            ProfileInfoRow(
                              icon: Icons.location_on_outlined,
                              label: "Dirección",
                              value: sesionState.office?.direccionCompleta ?? "Sin dirección",
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Center(
                    //   child: SizedBox(
                    //     width: MediaQuery.of(context).size.width * 0.38,
                    //     child: ElevatedButton(
                    //       onPressed: () {
                    //         buildShowModalBottomSheet(context);
                    //       },
                    //       style: ElevatedButton.styleFrom(
                    //         padding: const EdgeInsets.symmetric(vertical: 15),
                    //         shape: RoundedRectangleBorder(
                    //           borderRadius: BorderRadius.circular(8),
                    //         ),
                    //         backgroundColor: ColorSchema.primaryColor,
                    //       ),
                    //       child: Row(
                    //         mainAxisAlignment: MainAxisAlignment.center,
                    //         children: [
                    //           SvgPicture.asset(
                    //             "assets/icons/icon_svg/edit_icon.svg",
                    //             colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn),
                    //             width: 15,
                    //           ),
                    //           const SizedBox(
                    //             width: 8,
                    //           ),
                    //           Text(
                    //             "Edit Profile",
                    //             style: GoogleFonts.inter(
                    //               color: Colors.white,
                    //               fontSize: 16,
                    //               fontWeight: FontWeight.w600,
                    //             ),
                    //           )
                    //         ],
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    const SizedBox(height: 50),
                  ],
                ),
            ),
            Positioned(
                left: 10,
                child: SafeArea(
                  child: IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 24,
                    ),
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ))
          ],
        ),
      ),
    );
  }

  // void buildShowModalBottomSheet(BuildContext context) {
  //   showModalBottomSheet(
  //       backgroundColor: Colors.white,
  //       elevation: 0,
  //       shape: const RoundedRectangleBorder(
  //         borderRadius: BorderRadius.only(
  //           topLeft: Radius.circular(12),
  //           topRight: Radius.circular(12),
  //         ),
  //       ),
  //       isScrollControlled: true,
  //       context: context,
  //       builder: (_) {
  //         return SizedBox(
  //           height: MediaQuery.of(context).size.height * 0.9,
  //           child: const EditProfileSection(),
  //         );
  //       });
  // }
}
