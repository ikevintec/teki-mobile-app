import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_saas_admin/Screen/Widgets/Constant%20Data/constant.dart';
import 'package:salespro_saas_admin/model/shop_category_model.dart';

import '../../../../Provider/shop_category_provider.dart';

class EditCategory extends StatefulWidget {
  const EditCategory({Key? key, required this.editCategory}) : super(key: key);

  final ShopCategoryModel editCategory;

  @override
  State<EditCategory> createState() => _EditCategoryState();
}

class _EditCategoryState extends State<EditCategory> {
  String? categoryKey;

  void getCategory(String code) async {
    // ignore: unused_local_variable
    final userId = FirebaseAuth.instance.currentUser!.uid;
    // ignore: unused_local_variable
    List<ShopCategoryModel> categoryList = [];
    await FirebaseDatabase.instance.ref('Admin Panel').child('Category').orderByKey().get().then((value) {
      for (var element in value.children) {
        var data = ShopCategoryModel.fromJson(jsonDecode(jsonEncode(element.value)));
        if (data.categoryName == code) {
          categoryKey = element.key;
        }
      }
    });
  }

  TextEditingController categoryNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    categoryNameController.text = widget.editCategory.categoryName ?? '';
    descriptionController.text = widget.editCategory.description ?? '';
    getCategory(widget.editCategory.categoryName!);
    super.initState();
  }

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
                      'Edit Category',
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
                  onChanged: (value) {},
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
                            EasyLoading.show(status: 'Loading...', dismissOnTap: false);
                            try {
                              ShopCategoryModel shopCategoryModel = ShopCategoryModel(
                                categoryName: categoryNameController.text,
                                description: descriptionController.text,
                              );
                              // ignore: no_leading_underscores_for_local_identifiers
                              final DatabaseReference shopCategoryRef = FirebaseDatabase.instance.ref('Admin Panel').child('Category').child(categoryKey.toString());
                              // .child('Admin Panel')
                              // .child('Category');
                              await shopCategoryRef.update(shopCategoryModel.toJson());
                              // await shopCategoryRef.push().set(shopCategoryModel.toJson());
                              EasyLoading.showSuccess('Update Successfully!');
                              ref.refresh(shopCategoryProvider);
                              Future.delayed(const Duration(milliseconds: 100), () {
                                Navigator.pop(context);
                              });
                            } catch (e) {
                              // EasyLoading.dismiss();
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
                                'UPDATE',
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
