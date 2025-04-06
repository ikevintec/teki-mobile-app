import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:salespro_saas_admin/Provider/seller_info_provider.dart';
import 'package:salespro_saas_admin/model/seller_info_model.dart';

import '../../responsive.dart' as res;
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Sidebar/sidebar_widget.dart';
import '../Widgets/Table Widgets/Dashboard/dashboard_table.dart';
import '../Widgets/Table Widgets/Total Count/total_count_widget.dart';
import '../Widgets/Topbar/topbar.dart';

class MtDashboard extends StatefulWidget {
  const MtDashboard({Key? key}) : super(key: key);

  static const String route = '/dashBoard';

  @override
  State<MtDashboard> createState() => _MtDashboardState();
}

class _MtDashboardState extends State<MtDashboard> {
  int numberOfFree = 0;
  int numberOfYear = 0;
  int numberOfLifetime = 0;
  int newReg = 0;

  void getData() async {
    //var data = await FirebaseDatabase.instance.ref('Admin panel');
  }

  @override
  void initState() {
    getData();
    super.initState();
  }

  int i = 0;

  List<SellerInfoModel> lifetime = [];
  List<SellerInfoModel> expiredList = [];
  List<SellerInfoModel> todayRegistration = [];

  @override
  Widget build(BuildContext context) {
    i++;
    return Scaffold(
      backgroundColor: kDarkWhite,
      body: res.Responsive(
        mobile: Container(),
        tablet: const MtDashboard(),
        desktop: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              flex: 1,
              child: SideBarWidget(
                index: 0,
                isTab: false,
              ),
            ),
            Expanded(
              flex: 5,
              child: Consumer(
                builder: (_, ref, watch) {
                  AsyncValue<List<SellerInfoModel>> infoList = ref.watch(sellerInfoProvider);
                  return infoList.when(data: (infoList) {
                    DateTime t = DateTime.now();
                    if (i == 1) {
                      for (var element in infoList) {

                        if (element.subscriptionName == 'Free') {
                          numberOfFree++;
                        } else if (element.subscriptionName == 'Year') {
                          numberOfYear++;
                        } else if (element.subscriptionName == 'Lifetime') {
                          numberOfLifetime++;
                          lifetime.add(element);
                        }
                        if (DateTime.parse(element.subscriptionDate.toString()).difference(t).inHours.abs() <= 24) {
                          newReg++;
                          todayRegistration.add(element);
                        }
                        if (element.subscriptionName == 'Month') {
                          if (DateTime.parse(element.subscriptionDate.toString()).difference(t).inDays.abs() >= 23) {
                            expiredList.add(element);
                          }
                        }
                        if (element.subscriptionName == 'Year') {
                          if (DateTime.parse(element.subscriptionDate.toString()).difference(t).inDays.abs() >= 358) {
                            expiredList.add(element);
                          }
                        }
                      }
                    }
                    return Column(
                      children: [
                        //TopBar
                        Container(
                          padding: const EdgeInsets.all(6.0),
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: kWhiteTextColor,
                          ),
                          child: const TopBar(),
                        ),

                        //Counter
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              TotalCount(
                                icon: MdiIcons.accountGroup,
                                title: 'Total User',
                                count: infoList.length.toString(),
                                backgroundColor: const Color(0xFFFFDFE2),
                                iconBgColor: const Color(0xFFFF4A72),
                              ),
                              const SizedBox(width: 10.0),
                              TotalCount(
                                icon: MdiIcons.accountPlus,
                                title: 'New Registration',
                                count: newReg.toString(),
                                backgroundColor: const Color(0xFFFFF3DC),
                                iconBgColor: const Color(0xFFFFAA06),
                              ),
                              const SizedBox(width: 10.0),
                              TotalCount(
                                icon: FontAwesomeIcons.trophy,
                                title: 'Free Plan User',
                                count: numberOfFree.toString(),
                                backgroundColor: const Color(0xFFCDFFDE),
                                iconBgColor: const Color(0xFF2EE34D),
                              ),
                              const SizedBox(width: 10.0),
                              TotalCount(
                                icon: MdiIcons.crown,
                                title: 'Yearly Plan User',
                                count: numberOfYear.toString(),
                                backgroundColor: const Color(0xFFEFE1FF),
                                iconBgColor: const Color(0xFFB671FF),
                              ),
                              const SizedBox(width: 10.0),
                              TotalCount(
                                icon: FontAwesomeIcons.crown,
                                title: 'Life Time User Plan ',
                                count: numberOfLifetime.toString(),
                                backgroundColor: const Color(0xFFFFE1E1),
                                iconBgColor: const Color(0xFFFF436C),
                              ),
                            ],
                          ),
                        ),

                        // Dashboard Table
                        Padding(
                          padding: const EdgeInsets.only(left: 20.0, right: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  child: TopSellingStore(
                                todayReg: todayRegistration,
                              )),
                              const SizedBox(width: 20.0),
                              Expanded(
                                  child: LifetimeSubscribed(
                                lifeTimeSeller: lifetime,
                              )),
                              const SizedBox(width: 20.0),
                              Expanded(child: ExpiredShop(expiredShop: expiredList))
                            ],
                          ),
                        )
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
            ),
          ],
        ),
      ),
    );
  }
}
