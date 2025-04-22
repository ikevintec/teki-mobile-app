import 'package:flutter/material.dart';
import 'package:teki_app/src/utils/contstants.dart';

class UploadImage extends StatelessWidget {
  final String image;

  const UploadImage({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Stack(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade50.withOpacity(0.3),
            radius: 60,
            backgroundImage: AssetImage(image),
          ),
          const Positioned(
              right: 0,
              child: CircleAvatar(
                  radius: 18,
                  backgroundColor: ColorSchema.primaryColor,
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                  )))
        ],
      ),
    );
  }
}
