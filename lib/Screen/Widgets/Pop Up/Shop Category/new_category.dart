import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_saas_admin/Provider/shop_category_provider.dart';
import 'package:salespro_saas_admin/Screen/Widgets/Constant%20Data/constant.dart';
import 'package:salespro_saas_admin/model/shop_category_model.dart';

class NewCategory extends StatefulWidget {
  const NewCategory({Key? key}) : super(key: key);

  @override
  State<NewCategory> createState() => _NewCategoryState();
}

class _NewCategoryState extends State<NewCategory> {
  TextEditingController categoryNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, watch) {
        return SizedBox(
          width: 500,
          height: 350,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Add new Category',
                      style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold, fontSize: 18.0),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: (() => Navigator.pop(context)),
                      child: Container(
                        padding: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                          border: Border.all(
                            color: kRedTextColor.withOpacity(0.1),
                          ),
                        ),
                        child: const Icon(FeatherIcons.x, color: kRedTextColor),
                      ),
                    ),
                  ],
                ),
                const Divider(thickness: 1.0, color: kBorderColorTextField),
                const SizedBox(height: 20.0),
                TextField(
                  controller: categoryNameController,
                  showCursor: true,
                  cursorColor: kTitleColor,
                  decoration: kInputDecoration.copyWith(
                    labelText: 'Category Name',
                    labelStyle: kTextStyle.copyWith(color: kTitleColor),
                    hintText: 'Enter Category Name',
                    hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      borderSide: BorderSide(color: kBorderColorTextField, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  controller: descriptionController,
                  showCursor: true,
                  cursorColor: kTitleColor,
                  maxLines: 4,
                  decoration: kInputDecoration.copyWith(
                    labelText: 'Description',
                    labelStyle: kTextStyle.copyWith(color: kTitleColor),
                    hintText: 'Enter Category Description',
                    hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      borderSide: BorderSide(color: kBorderColorTextField, width: 2),
                    ),
                  ),
                ),
                const Spacer(),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: (() => Navigator.pop(context)),
                        child: Container(
                          padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 5.0, bottom: 5.0),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0), border: Border.all(color: kRedTextColor), color: Colors.transparent),
                          child: Column(
                            children: [
                              Text(
                                'CANCEL',
                                style: kTextStyle.copyWith(color: kRedTextColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      GestureDetector(
                        onTap: () async {
                          if (categoryNameController.text.isEmpty) {
                            EasyLoading.showError('Category Name Is Required');
                          } else {
                            try {
                              EasyLoading.show(status: 'Loading...', dismissOnTap: false);
                              // ignore: no_leading_underscores_for_local_identifiers
                              final DatabaseReference shopCategoryRef = FirebaseDatabase.instance.ref().child('Admin Panel').child('Category');
                              ShopCategoryModel shopCategoryModel = ShopCategoryModel(
                                categoryName: categoryNameController.text,
                                description: descriptionController.text,
                              );
                              await shopCategoryRef.push().set(shopCategoryModel.toJson());
                              EasyLoading.showSuccess('Added Successfully!');
                              ref.refresh(shopCategoryProvider);
                              Future.delayed(const Duration(milliseconds: 100), () {
                                Navigator.pop(context);
                              });
                            } catch (e) {
                              EasyLoading.dismiss();
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 5.0, bottom: 5.0),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0), color: kBlueTextColor),
                          child: Column(
                            children: [
                              Text(
                                'SAVE',
                                style: kTextStyle.copyWith(color: kWhiteTextColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
