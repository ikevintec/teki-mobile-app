import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../Provider/seller_info_provider.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Constant Data/export_button.dart';
import '../Widgets/Pop Up/Reports/view_reports.dart';
import '../Widgets/Sidebar/sidebar_widget.dart';
import '../Widgets/Topbar/topbar.dart';

class Reports extends StatefulWidget {
  const Reports({Key? key}) : super(key: key);

  static const String route = '/reports';

  @override
  State<Reports> createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  void showViewReportPopUp() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: const ViewReport(),
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
          final reports = ref.watch(sellerInfoProvider);
          return reports.when(data: (reports) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  flex: 1,
                  child: SideBarWidget(
                    index: 4,
                    isTab: false,
                  ),
                ),
                Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
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
                                  Text(
                                    'REPORTS',
                                    style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 10.0),
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
                                  const SizedBox(height: 10.0).visible(false),
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
                                      headingTextStyle: kTextStyle.copyWith(color: kTitleColor, fontSize: 14.0),
                                      dataTextStyle: kTextStyle.copyWith(color: kGreyTextColor, fontSize: 12.0),
                                      horizontalMargin: 20.0,
                                      columnSpacing: 20.0,
                                      columns: const [
                                        DataColumn(
                                          label: Text('DATE'),
                                        ),
                                        DataColumn(
                                          label: Text('SHOP NAME'),
                                        ),
                                        DataColumn(
                                          label: Text('CATEGORY'),
                                        ),
                                        DataColumn(
                                          label: Text('PACKAGE'),
                                        ),
                                        DataColumn(
                                          label: Text('START'),
                                        ),
                                        DataColumn(
                                          label: Text('END'),
                                        ),
                                        DataColumn(
                                          label: Text('METHOD'),
                                        ),
                                        DataColumn(
                                          label: Text('ACTION'),
                                        ),
                                      ],
                                      rows: List.generate(
                                        reports.length,
                                        (index) => DataRow(
                                          cells: [
                                            DataCell(
                                              Text(reports[index].subscriptionDate?.substring(0, 10) ?? ''),
                                            ),
                                            DataCell(
                                              Text(reports[index].companyName ?? ''),
                                            ),
                                            DataCell(
                                              Text(reports[index].businessCategory ?? ''),
                                            ),
                                            DataCell(
                                              Text(reports[index].subscriptionName ?? ''),
                                            ),
                                            DataCell(
                                              Text(reports[index].subscriptionDate?.substring(0, 10) ?? ''),
                                            ),
                                            DataCell(
                                              Text(reports[index].subscriptionDate?.substring(0, 10) ?? ''),
                                            ),
                                            DataCell(
                                              Text(reports[index].subscriptionMethod ?? ''),
                                            ),
                                            DataCell(
                                              PopupMenuButton(
                                                icon: const Icon(FeatherIcons.moreVertical, size: 18.0),
                                                padding: EdgeInsets.zero,
                                                itemBuilder: (BuildContext bc) => [
                                                  PopupMenuItem(
                                                    child: GestureDetector(
                                                      onTap: (() => showViewReportPopUp()),
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
                    ))
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
