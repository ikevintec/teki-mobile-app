import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nb_utils/nb_utils.dart';

import '../Constant Data/constant.dart';

class TopBar extends StatelessWidget {
  const TopBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
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
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: kBlueTextColor,
                  ),
                  child: const Icon(FeatherIcons.search, color: kWhiteTextColor),
                ),
              ),
              hintStyle: kTextStyle.copyWith(color: kLitGreyColor),
              contentPadding: const EdgeInsets.all(4.0),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(30.0),
                ),
                borderSide: BorderSide(color: kBorderColorTextField, width: 1),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(30.0)),
                borderSide: BorderSide(color: kBorderColorTextField, width: 2),
              ),
            ),
          ),
        ).visible(false),
        const Spacer(),
        Icon(MdiIcons.bellOutline, color: kTitleColor).visible(false),
        const SizedBox(width: 5.0),
        PopupMenuButton(
          padding: EdgeInsets.zero,
          itemBuilder: (BuildContext bc) => [
            PopupMenuItem(
              child: Text(
                'English',
                style: kTextStyle.copyWith(color: kTitleColor),
              ),
            ),
            PopupMenuItem(
              child: Text(
                'Bangla',
                style: kTextStyle.copyWith(color: kTitleColor),
              ),
            ),
            PopupMenuItem(
              child: Text(
                'Hindi',
                style: kTextStyle.copyWith(color: kTitleColor),
              ),
            ),
          ],
          onSelected: (value) {
            Navigator.pushNamed(context, '$value');
          },
          child: Container(
            height: 25,
            width: 25,
            decoration: const BoxDecoration(
              image: DecorationImage(image: AssetImage('images/eng.png'), fit: BoxFit.cover),
            ),
          ),
        ).visible(false),
        const SizedBox(width: 5.0),
        Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: kBlueTextColor.withOpacity(0.1),
                ),
                child: const Icon(FeatherIcons.logOut, color: kBlueTextColor))
            .onTap(() async {
          await FirebaseAuth.instance.signOut();
          // ignore: use_build_context_synchronously
          Navigator.pushNamed(context, '/');
        }),
      ],
    );
  }
}
