import 'package:flutter/material.dart';
import 'package:salespro_saas_admin/Screen/Widgets/Constant%20Data/constant.dart';

class TotalCount extends StatelessWidget {
  const TotalCount({Key? key, required this.title, required this.count, required this.icon, required this.backgroundColor, required this.iconBgColor}) : super(key: key);

  final String title;
  final String count;
  final Color iconBgColor;
  final IconData icon;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: backgroundColor,
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                title,
                style: kTextStyle.copyWith(color: kGreyTextColor),
                maxLines: 1,
              ),
              subtitle: Text(
                count,
                style: kTextStyle.copyWith(color: kTitleColor, fontSize: 21.0, fontWeight: FontWeight.bold),
              ),
              trailing: Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(shape: BoxShape.circle, color: iconBgColor),
                child: Icon(icon, color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}
