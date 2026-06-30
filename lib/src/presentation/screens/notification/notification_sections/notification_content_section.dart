import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';

class NotificationContentScreen extends StatelessWidget {
  const NotificationContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationData = Get.arguments;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(
          navigateName: "Message",
        ),
      ),
      body: Container(
        color: Colors.white70,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage(notificationData["image"]),
                    radius: screenWidth * 0.1,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notificationData["name"],
                        style: GoogleFonts.raleway(
                            textStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.05,
                          color: Colors.black,
                        )),
                      ),
                      Text(
                        "${notificationData["date"]} ${notificationData["time"]}",
                        style: GoogleFonts.roboto(
                            textStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: screenWidth * 0.035)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Divider(
                color: Colors.grey.shade300,
                thickness: 1,
                height: 20,
              ),
              const SizedBox(
                height: 20,
              ),
              Expanded(
                  child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                child: ListView(
                  children: [
                    Text(
                      "Hi,",
                      style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                              color: const Color(0xFF616161),
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    Text(
                      notificationData["messageContent"],
                      style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                              fontSize: screenWidth * 0.04,
                              color: const Color(0xFF616161))),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      notificationData["messageBody"],
                      style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                              fontSize: screenWidth * 0.04,
                              color: const Color(0xFF616161))),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      notificationData["messageEnd"],
                      style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                              fontSize: screenWidth * 0.04,
                              color: const Color(0xFF616161))),
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    Text(
                      "Thanks!",
                      style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                              color: const Color(0xFF616161),
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(
                      height: 20,
                    )
                  ],
                ),
              )),
              const SizedBox(
                height: 100,
              )
            ],
          ),
        ),
      ),
    );
  }
}
