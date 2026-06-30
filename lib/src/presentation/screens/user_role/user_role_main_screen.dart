import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/management_model/user_role_model.dart';
import 'package:teki_app/src/presentation/screens/user_role/user_role_sections/user_role_update_section.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/button/custom_elevated_button.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/delete_toast.dart';
import 'package:teki_app/src/presentation/widgets/toast/success_toast.dart';

class UserRoleMainScreen extends StatefulWidget {
  const UserRoleMainScreen({super.key});

  @override
  State<UserRoleMainScreen> createState() => _UserRoleMainScreenState();
}

class _UserRoleMainScreenState extends State<UserRoleMainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(navigateName: "User Role"),
      ),
      body: Container(
        color: Colors.white70,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(
              height: 20,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFieldSection(
                  label: "Role",
                  hint: "Enter Role",
                  inputType: TextInputType.text),
            ),
            const SizedBox(
              height: 20,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFieldSection(
                  label: "Description",
                  hint: 'Enter Description',
                  inputType: TextInputType.text),
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CustomElevatedButton(
                  buttonName: "Create Role",
                  showToast: () {
                    SuccessToast.showSuccessToast(
                        context, "Create Complete", "Role Create Complete");
                  }),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Existing User Role",
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
                child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: userRoleModel.length,
              itemBuilder: (context, index) {
                final userRole = userRoleModel[index];
                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    "assets/icons/icon_svg/profile_name.svg",
                                    width: 18,
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  Text(
                                    userRole["role"],
                                    style: GoogleFonts.raleway(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      color: const Color(0xFF444444),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Text(
                                userRole["description"],
                                style: GoogleFonts.roboto(
                                    color: const Color(0xFF5F6672)),
                              )
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 35,
                              height: 35,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: Colors.blue.shade50.withOpacity(0.5),
                              ),
                              child: IconButton(
                                icon: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: SvgPicture.asset(
                                    "assets/icons/icon_svg/edit_icon.svg",
                                    color: Colors.blue,
                                  ),
                                ),
                                onPressed: () {
                                  buildModalBottomSheet(context, userRole);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 35,
                              height: 35,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: Colors.red.shade50.withOpacity(0.5),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  DeleteToast.showDeleteToast(
                                      context, userRole["role"]);
                                  setState(() {
                                    userRoleModel.removeAt(index);
                                  });
                                },
                                icon: SvgPicture.asset(
                                  "assets/icons/icon_svg/delete_icon.svg",
                                  color: Colors.red,
                                ),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            )),
          ],
        ),
      ),
    );
  }

  void buildModalBottomSheet(BuildContext context, user) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      elevation: 0,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      context: context,
      builder: (_) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: UserRoleUpdateSection(user: user),
        );
      },
    );
  }
}
