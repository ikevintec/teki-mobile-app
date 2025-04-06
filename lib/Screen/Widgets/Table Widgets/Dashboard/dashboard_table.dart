import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:salespro_saas_admin/Screen/Widgets/Constant%20Data/constant.dart';

import '../../../../model/seller_info_model.dart';

//Top Selling Store
class TopSellingStore extends StatelessWidget {
  const TopSellingStore({Key? key, required this.todayReg}) : super(key: key);
  final List<SellerInfoModel> todayReg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: kWhiteTextColor),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            horizontalTitleGap: 0,
            leading: Icon(
              MdiIcons.bank,
              color: kGreyTextColor,
            ),
            title: Text(
              'Today Registered',
              style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
            ),
          ),
          Row(
            children: List.generate(
                800 ~/ 5,
                (index) => Expanded(
                      child: Container(
                        color: index % 2 == 0 ? Colors.transparent : Colors.grey,
                        height: 1,
                      ),
                    )),
          ),
          ListView.builder(
            itemCount: todayReg.length < 5 ? todayReg.length : 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (_, i) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                horizontalTitleGap: 0,
                title: Text(
                  todayReg[i].companyName.toString(),
                  style: kTextStyle.copyWith(color: kTitleColor),
                ),
                subtitle: Text(
                  todayReg[i].businessCategory.toString(),
                  style: kTextStyle.copyWith(color: kBlueTextColor),
                ),
                trailing: Text(
                  'Today',
                  style: kTextStyle.copyWith(color: kGreyTextColor),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

//Lifetime Subscribed
class LifetimeSubscribed extends StatelessWidget {
  const LifetimeSubscribed({Key? key, required this.lifeTimeSeller}) : super(key: key);
  final List<SellerInfoModel> lifeTimeSeller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: kWhiteTextColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            horizontalTitleGap: 0,
            leading: Icon(
              MdiIcons.accountGroupOutline,
              color: kGreyTextColor,
            ),
            title: Text(
              'Lifetime Subscribed',
              style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
            ),
          ),
          Row(
            children: List.generate(
                800 ~/ 5,
                (index) => Expanded(
                      child: Container(
                        color: index % 2 == 0 ? Colors.transparent : Colors.grey,
                        height: 1,
                      ),
                    )),
          ),
          ListView.builder(
            itemCount: lifeTimeSeller.length < 5 ? lifeTimeSeller.length : 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (_, i) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                horizontalTitleGap: 20,
                leading: CircleAvatar(
                  radius: 20.0,
                  backgroundImage: NetworkImage(lifeTimeSeller[i].pictureUrl ?? ''),
                ),
                title: Text(
                  lifeTimeSeller[i].companyName.toString(),
                  style: kTextStyle.copyWith(color: kTitleColor),
                ),
                subtitle: Text(
                  lifeTimeSeller[i].businessCategory.toString(),
                  style: kTextStyle.copyWith(color: kBlueTextColor),
                ),
                trailing: Text(
                  lifeTimeSeller[i].subscriptionDate.toString().substring(0, 10),
                  style: kTextStyle.copyWith(color: kTitleColor),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

//Expired Shop
class ExpiredShop extends StatelessWidget {
  const ExpiredShop({Key? key, required this.expiredShop}) : super(key: key);
  final List<SellerInfoModel> expiredShop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: kWhiteTextColor),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            horizontalTitleGap: 0,
            leading: Icon(
              MdiIcons.clockAlertOutline,
              color: kGreyTextColor,
            ),
            title: Text(
              'Expired Shop',
              style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              'Package',
              style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
            ),
          ),
          Row(
            children: List.generate(
                800 ~/ 5,
                (index) => Expanded(
                      child: Container(
                        color: index % 2 == 0 ? Colors.transparent : Colors.grey,
                        height: 1,
                      ),
                    )),
          ),
          ListView.builder(
            itemCount: expiredShop.length < 5 ? expiredShop.length : 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (_, i) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                horizontalTitleGap: 0,
                title: Text(
                  expiredShop[i].companyName.toString(),
                  style: kTextStyle.copyWith(color: kTitleColor),
                ),
                subtitle: Text(
                  expiredShop[i].businessCategory.toString(),
                  style: kTextStyle.copyWith(color: kBlueTextColor),
                ),
                trailing: Text(
                  expiredShop[i].subscriptionDate.toString().substring(0, 10),
                  style: kTextStyle.copyWith(color: kGreyTextColor),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
