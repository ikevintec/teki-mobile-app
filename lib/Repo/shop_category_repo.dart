import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:salespro_saas_admin/model/shop_category_model.dart';



class ShopCategoryRepo {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  Future<List<ShopCategoryModel>> getAllCategory() async {
    List<ShopCategoryModel> categoryList = [];


    await FirebaseDatabase.instance.ref('Admin Panel').child('Category').orderByKey().get().then((value) {
      for (var element in value.children) {
        var data = ShopCategoryModel.fromJson(jsonDecode(jsonEncode(element.value)));
        categoryList.add(data);
      }
    });
    return categoryList;
  }
}