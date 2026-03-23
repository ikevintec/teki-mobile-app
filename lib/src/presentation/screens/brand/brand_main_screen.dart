import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/products_model/product_brand_model.dart';
import 'package:teki_app/src/presentation/screens/brand/brand_sections/update_brand_screen.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/button/custom_elevated_button.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/delete_toast.dart';
import 'package:teki_app/src/presentation/widgets/toast/success_toast.dart';
import 'package:teki_app/src/presentation/widgets/upload_image/upload_image.dart';

class BrandMainScreen extends StatefulWidget {
  const BrandMainScreen({super.key});

  @override
  BrandMainScreenState createState() => BrandMainScreenState();
}

class BrandMainScreenState extends State<BrandMainScreen> {
  TextEditingController brandNameController = TextEditingController();
  List<Map<String, dynamic>> brandList = List.from(productBrandModel);

  String image = "assets/images/logo/dell.png";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(navigateName: "Brand"),
      ),
      body: Container(
        color: Colors.white70,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(
              height: 20,
            ),
            UploadImage(image: image,
            onImageSelected: (newImage,file) {
              setState(() {
                image = newImage;
              });
            },
            ),
            const SizedBox(height: 20),
            const TextFieldSection(
              label: "Brand",
              hint: "Enter Brand Name",
              inputType: TextInputType.name,
            ),
            const SizedBox(height: 20),
            CustomElevatedButton(
              buttonName: "Create Brand",
              showToast: () {
                SuccessToast.showSuccessToast(
                    context, "Create Complete", "Brand Create Complete");
              },
            ),
            const SizedBox(height: 40),
            Text(
              "Existing Brands",
              style: GoogleFonts.raleway(
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: brandList.length,
                separatorBuilder: (context, index) => const SizedBox(
                  height: 15,
                  child: Divider(
                    color: Color(0xFFE2E4E7),
                  ),
                ),
                itemBuilder: (context, index) {
                  var brand = brandList[index];
                  return ListTile(
                    leading: Image.asset(
                      brand["brand-image"],
                      width: 50,
                      height: 50,
                    ),
                    title: Text(
                      brand["brand-name"],
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w500),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: Colors.blue.shade50.withOpacity(0.3),
                          ),
                          child: IconButton(
                            onPressed: () {
                              buildModalBottomSheet(context, brand);
                            },
                            icon: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: SvgPicture.asset(
                                "assets/icons/icon_svg/edit_icon.svg",
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: Colors.red.shade50.withOpacity(0.3),
                          ),
                          child: IconButton(
                            onPressed: () {
                              DeleteToast.showDeleteToast(
                                  context, brand["brand-name"]);

                              setState(() {
                                brandList.removeAt(index);
                              });
                            },
                            icon: SvgPicture.asset(
                              "assets/icons/icon_svg/delete_icon.svg",
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void buildModalBottomSheet(BuildContext context, brand) {
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
          height: MediaQuery.of(context).size.height * 0.8,
          child: UpdateBrandScreen(brand: brand),
        );
      },
    );
  }
}
