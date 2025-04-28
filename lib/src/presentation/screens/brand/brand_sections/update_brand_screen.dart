import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/widgets/button/custom_elevated_button.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/success_toast.dart';
import 'package:teki_app/src/presentation/widgets/upload_image/upload_image.dart';

class UpdateBrandScreen extends StatelessWidget {
  final dynamic brand;

  const UpdateBrandScreen({super.key, required this.brand});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white70,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    "Edit Brand",
                    style: GoogleFonts.raleway(
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Color(0xFF444444),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 26,
                    color: Color(0xFF444444),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            ),
          ),
          Divider(
            color: Colors.grey.shade300,
          ),
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              UploadImage(image: brand["brand-image"],
              onImageSelected: (newImage,file) {
                brand["brand-iamge"] = newImage;
              },
              ),
              const SizedBox(
                height: 20,
              ),
              TextFieldSection(
                  label: "Brand",
                  hint: brand["brand-name"],
                  inputType: TextInputType.name),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: double.maxFinite,
                child: CustomElevatedButton(
                    buttonName: "Update",
                    showToast: () {
                      SuccessToast.showSuccessToast(context, "Update Complete",
                          "${brand["brand-name"]} Update Complete");
                    }),
              ),
              const SizedBox(
                height: 20,
              ),
            ]),
          )
        ],
      ),
    );
  }
}
