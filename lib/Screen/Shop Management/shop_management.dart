import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_saas_admin/Provider/seller_info_provider.dart';
import 'package:salespro_saas_admin/Screen/Widgets/Pop%20Up/Shop%20Management/view_shop.dart';
import 'package:salespro_saas_admin/model/seller_info_model.dart';

import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Constant Data/export_button.dart';
import '../Widgets/Pop Up/Shop Management/edit_shop.dart';
import '../Widgets/Sidebar/sidebar_widget.dart';
import '../Widgets/Topbar/topbar.dart';

class ShopManagement extends StatefulWidget {
  const ShopManagement({Key? key}) : super(key: key);

  static const String route = '/shopManagement';

  @override
  State<ShopManagement> createState() => _ShopManagementState();
}

class _ShopManagementState extends State<ShopManagement> {
  //View Shop PopUp
  void showViewShopPopUp(SellerInfoModel info) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: ViewShop(
            infoModel: info,
          ),
        );
      },
    );
  }

  //Edit Shop PopUp
  void showEditShopPopUp(SellerInfoModel shopInfo) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: EditShop(shopInformation: shopInfo),
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
          final sellerInfo = ref.watch(sellerInfoProvider);
          return sellerInfo.when(data: (sellerInfo) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  flex: 1,
                  child: SideBarWidget(
                    index: 1,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'SHOP LIST',
                                      style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                    ),
                                    const Spacer(),
                                    const ExportButton().visible(false)
                                  ],
                                ),
                                // const SizedBox(height: 10.0),
                                // SizedBox(
                                //   height: 40,
                                //   width: MediaQuery.of(context).size.width * .25,
                                //   child: TextField(
                                //     showCursor: true,
                                //     cursorColor: kTitleColor,
                                //     decoration: kInputDecoration.copyWith(
                                //       hintText: 'Search Anything...',
                                //       suffixIcon: Padding(
                                //         padding: const EdgeInsets.all(4.0),
                                //         child: Container(
                                //           decoration: BoxDecoration(
                                //             borderRadius: BorderRadius.circular(8.0),
                                //             color: kBlueTextColor,
                                //           ),
                                //           child: const Icon(FeatherIcons.search, color: kWhiteTextColor),
                                //         ),
                                //       ),
                                //       hintStyle: kTextStyle.copyWith(color: kLitGreyColor),
                                //       contentPadding: const EdgeInsets.all(4.0),
                                //       enabledBorder: const OutlineInputBorder(
                                //         borderRadius: BorderRadius.all(
                                //           Radius.circular(8.0),
                                //         ),
                                //         borderSide: BorderSide(color: kBorderColorTextField, width: 1),
                                //       ),
                                //     ),
                                //   ),
                                // ),
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
                                    headingTextStyle: kTextStyle.copyWith(color: kTitleColor,fontSize: 14.0),
                                    dataTextStyle: kTextStyle.copyWith(color: kGreyTextColor,fontSize: 12.0),
                                    horizontalMargin: 20.0,
                                    columnSpacing: 20.0,
                                    columns: const [
                                      DataColumn(
                                        label: Text('S.L'),
                                      ),
                                      DataColumn(
                                        label: Text('LOGO'),
                                      ),
                                      DataColumn(
                                        label: Text('SHOP NAME'),
                                      ),
                                      DataColumn(
                                        label: Text('CATEGORY'),
                                      ),
                                      DataColumn(
                                        label: Text('PHONE'),
                                      ),
                                      DataColumn(
                                        label: Text('EMAIL'),
                                      ),
                                      DataColumn(
                                        label: Text('PACKAGE'),
                                      ),
                                      DataColumn(
                                        label: Text('METHOD'),
                                      ),
                                      DataColumn(
                                        label: Text('ACTION'),
                                      ),
                                    ],
                                    rows: List.generate(
                                      sellerInfo.length,
                                      (index) => DataRow(
                                        cells: [
                                          DataCell(
                                            Text((index + 1).toString()),
                                          ),
                                          DataCell(
                                            CircleAvatar(
                                              radius: 20.0,
                                              backgroundImage: NetworkImage(sellerInfo[index].pictureUrl ?? ''),
                                            ),
                                          ),
                                          DataCell(
                                            Text(sellerInfo[index].companyName ?? ''),
                                          ),
                                          DataCell(
                                            Text(sellerInfo[index].businessCategory ?? ''),
                                          ),
                                          DataCell(
                                            Text(sellerInfo[index].phoneNumber ?? ''),
                                          ),
                                          DataCell(
                                            Text(sellerInfo[index].email ?? ''),
                                          ),
                                          DataCell(
                                            Text(sellerInfo[index].subscriptionName ?? ''),
                                          ),
                                          DataCell(
                                            Text(sellerInfo[index].subscriptionMethod ?? ''),
                                          ),
                                          DataCell(
                                            PopupMenuButton(
                                              icon: const Icon(FeatherIcons.moreVertical, size: 18.0),
                                              padding: EdgeInsets.zero,
                                              itemBuilder: (BuildContext bc) => [
                                                PopupMenuItem(
                                                  child: GestureDetector(
                                                    onTap: (() => showViewShopPopUp(sellerInfo[index])),
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
                                                // PopupMenuItem(
                                                //   child: GestureDetector(
                                                //     onTap: (() => showEditShopPopUp(sellerInfo[index])),
                                                //     child: Row(
                                                //       children: [
                                                //         const Icon(FeatherIcons.edit3, size: 18.0, color: kTitleColor),
                                                //         const SizedBox(width: 4.0),
                                                //         Text(
                                                //           'Edit',
                                                //           style: kTextStyle.copyWith(color: kTitleColor),
                                                //         ),
                                                //       ],
                                                //     ).visible(false),
                                                //   ),
                                                // ),
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
