import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/utils/contstants.dart';

class ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ColorSchema.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: ColorSchema.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
        Divider(color: Colors.grey.shade300),
        const SizedBox(height: 15),
      ],
    );
  }
}
