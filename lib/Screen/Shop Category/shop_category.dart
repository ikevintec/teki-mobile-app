import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_saas_admin/Provider/shop_category_provider.dart';
import 'package:salespro_saas_admin/model/shop_category_model.dart';

import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Constant Data/export_button.dart';
import '../Widgets/Pop Up/Shop Category/edit_category.dart';
import '../Widgets/Pop Up/Shop Category/new_category.dart';
import '../Widgets/Pop Up/Shop Category/view_category.dart';
import '../Widgets/Sidebar/sidebar_widget.dart';
import '../Widgets/Topbar/topbar.dart';

class ShopCategory extends StatefulWidget {
  const ShopCategory({Key? key}) : super(key: key);

  static const String route = '/shopCategory';

  @override
  State<ShopCategory> createState() => _ShopCategoryState();
}

class _ShopCategoryState extends State<ShopCategory> {
  //Add New Category PopUp
  void showAddCategoryPopUp() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: const NewCategory(),
        );
      },
    );
  }

  //VIEW Category PopUp
  void showViewCategoryPopUP(ShopCategoryModel category) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: ViewCategory(categoryModel: category),
        );
      },
    );
  }

  //Show Edit Category
  void showEditCategory(ShopCategoryModel edit) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: EditCategory(editCategory: edit),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      body: Consumer(
        builder: (_, ref, watch) {
          AsyncValue<List<ShopCategoryModel>> categoryList = ref.watch(shopCategoryProvider);
          return categoryList.when(data: (categoryList) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  flex: 1,
                  child: SideBarWidget(
                    index: 2,
                    isTab: false,
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6.0),
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: kWhiteTextColor,
                          ),
                          child: const TopBar(),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: kWhiteTextColor),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'SHOP LIST',
                                      style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: (() => showAddCategoryPopUp()),
                                      child: Container(
                                        padding: const EdgeInsets.all(5.0),
                                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0), color: kBlueTextColor),
                                        child: Column(
                                          children: [
                                            Text(
                                              'ADD NEW CATEGORY',
                                              style: kTextStyle.copyWith(color: kWhiteTextColor),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),

                                Row(
                                  children: [
                                    SizedBox(
                                      height: 40,
                                      width: MediaQuery.of(context).size.width * .25,
                                      child: TextField(
                                        showCursor: true,
                                        cursorColor: kTitleColor,
                                        decoration: kInputDecoration.copyWith(
                                          hintText: 'Search Anything...',
                                          suffixIcon: Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8.0),
                                                color: kBlueTextColor,
                                              ),
                                              child: const Icon(FeatherIcons.search, color: kWhiteTextColor),
                                            ),
                                          ),
                                          hintStyle: kTextStyle.copyWith(color: kLitGreyColor),
                                          contentPadding: const EdgeInsets.all(4.0),
                                          enabledBorder: const OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(8.0),
                                            ),
                                            borderSide: BorderSide(color: kBorderColorTextField, width: 1),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    const ExportButton()
                                  ],
                                ).visible(false),
                                const SizedBox(height: 10.0),
                                SizedBox(
                                  width: double.infinity,
                                  child: DataTable(
                                    border: TableBorder.all(
                                      color: kBorderColorTextField,
                                      borderRadius: BorderRadius.circular(5.0),
                                    ),
                                    dividerThickness: 1.0,
                                    headingRowColor: MaterialStateProperty.all(kDarkWhite),
                                    showBottomBorder: true,
                                    headingTextStyle: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                    dataTextStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                    columns: const [
                                      DataColumn(
                                        label: Text('S.L'),
                                      ),
                                      DataColumn(
                                        label: Text('CATEGORY NAME'),
                                      ),
                                      DataColumn(
                                        label: Text('DESCRIPTION'),
                                      ),
                                      DataColumn(
                                        label: Text('CREATED BY'),
                                      ),
                                      DataColumn(
                                        label: Text('ACTION'),
                                      ),
                                    ],
                                    rows: List.generate(
                                      categoryList.length,
                                      (index) => DataRow(
                                        cells: [
                                          DataCell(
                                            Text((index + 1).toString()),
                                          ),
                                          DataCell(
                                            Text(categoryList[index].categoryName ?? ''),
                                          ),
                                          DataCell(
                                            Text(categoryList[index].description ?? ''),
                                          ),
                                          const DataCell(
                                            Text('Admin'),
                                          ),
                                          DataCell(
                                            PopupMenuButton(
                                              icon: const Icon(FeatherIcons.moreVertical, size: 18.0),
                                              padding: EdgeInsets.zero,
                                              itemBuilder: (BuildContext bc) => [
                                                PopupMenuItem(
                                                  child: GestureDetector(
                                                    onTap: (() => showViewCategoryPopUP(
                                                          categoryList[index],
                                                        )),
                                                    child: Row(
                                                      children: [
                                                        const Icon(FeatherIcons.eye, size: 18.0, color: kTitleColor),
                                                        const SizedBox(width: 4.0),
                                                        Text(
                                                          'View',
                                                          style: kTextStyle.copyWith(color: kTitleColor),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  child: GestureDetector(
                                                    onTap: (() => showEditCategory(categoryList[index])),
                                                    child: Row(
                                                      children: [
                                                        const Icon(FeatherIcons.edit3, size: 18.0, color: kTitleColor),
                                                        const SizedBox(width: 4.0),
                                                        Text(
                                                          'Edit',
                                                          style: kTextStyle.copyWith(color: kTitleColor),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              onSelected: (value) {
                                                Navigator.pushNamed(context, '$value');
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            );
          }, error: (e, stack) {
            return Center(
              child: Text(e.toString()),
            );
          }, loading: () {
            return const Center(
              child: CircularProgressIndicator(),
            );
          });
        },
      ),
    );
  }
}
