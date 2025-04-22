import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/notification_model/notification_model.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/routes/app_routes.dart';

class NotificationMainScreen extends StatelessWidget {
  const NotificationMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(
          navigateName: "Notification",
        ),
      ),
      body: Container(
          color: Colors.white70,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildNotificationList()),
    );
  }

  Widget _buildNotificationList() {
    return ListView.builder(
      itemCount: notificationModel.length,
      itemBuilder: (context, index) {
        return _buildNotificationSection(notificationModel[index]);
      },
    );
  }

  Widget _buildNotificationSection(Map<String, dynamic> notifications) {
    List<Widget> todayNotifications = [];
    List<Widget> yesterdayNotifications = [];

    if (notifications.containsKey("today")) {
      for (var notification in notifications["today"]) {
        todayNotifications.add(_buildNotificationItem(notification));
      }
    }

    if (notifications.containsKey("yesterday")) {
      for (var notification in notifications["yesterday"]) {
        yesterdayNotifications.add(_buildNotificationItem(notification));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (todayNotifications.isNotEmpty) ...[
          _buildSectionHeader("Today"),
          _buildNotificationItems(todayNotifications),
          const SizedBox(height: 16),
        ],
        if (yesterdayNotifications.isNotEmpty) ...[
          _buildSectionHeader("Yesterday"),
          _buildNotificationItems(yesterdayNotifications),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      color: Colors.white,
      child: Text(
        title,
        style: GoogleFonts.raleway(
            textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildNotificationItems(List<Widget> notifications) {
    return Column(
      children: notifications,
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    return InkWell(
      onTap: () {
        Get.toNamed(AppRoutes.notificationContent, arguments: notification);
      },
      child: Padding(
        padding: const EdgeInsets.only(
          top: 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Image.asset(
                      notification["image"],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 15,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${notification["name"]} sent you",
                        style: GoogleFonts.roboto(
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        "Message",
                        style: GoogleFonts.nunito(
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${notification["date"]}",
                            style: GoogleFonts.nunito(
                              textStyle: const TextStyle(color: Colors.grey),
                            ),
                          ),
                          Text(
                            "${notification["time"]}",
                            style: GoogleFonts.nunito(
                              textStyle: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Divider(
              color: Colors.grey[200],
              thickness: 1.5,
            ),
          ],
        ),
      ),
    );
  }
}
