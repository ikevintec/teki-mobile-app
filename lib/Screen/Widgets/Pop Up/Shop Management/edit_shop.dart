import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_saas_admin/Screen/Widgets/Constant%20Data/constant.dart';
import 'package:salespro_saas_admin/model/seller_info_model.dart';

class EditShop extends StatefulWidget {
  const EditShop({Key? key,required this.shopInformation}) : super(key: key);

  final SellerInfoModel shopInformation;

  @override
  State<EditShop> createState() => _EditShopState();
}

class _EditShopState extends State<EditShop> {
//Business Category
  List<String> businessCategory = [
    'Electronics',
    'Fashion',
    'Sweet Store'
  ];

  String selectedCategories = 'Electronics';

  DropdownButton<String> getBusinessCategories() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in businessCategory) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      items: dropDownItems,
      value: selectedCategories,
      onChanged: (value) {
        setState(() {
          selectedCategories = value!;
        });
      },
    );
  }

//Package
  List<String> package = ['Yearly', 'Monthly', 'Life Time'];

  String selectedPackage = 'Yearly';

  DropdownButton<String> getPackage() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in package) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      items: dropDownItems,
      value: selectedPackage,
      onChanged: (value) {
        setState(() {
          selectedPackage = value!;
        });
      },
    );
  }

  //Payment Method
  List<String> paymentMethod = [
    'Paypal',
    'Bank',
  ];

  String selectedMethod = 'Paypal';

  DropdownButton<String> getMethod() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in paymentMethod) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      items: dropDownItems,
      value: selectedMethod,
      onChanged: (value) {
        setState(() {
          selectedMethod = value!;
        });
      },
    );
  }


  TextEditingController shopNameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    selectedCategories = widget.shopInformation.businessCategory ?? '';
    shopNameController.text = widget.shopInformation.companyName ?? '';
    phoneNumberController.text = widget.shopInformation.phoneNumber ?? '';
    emailController.text = widget.shopInformation.email ?? '';

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, watch) {
        return SizedBox(
          width: 800,
          height: 500,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'EDIT SHOP',
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
                const SizedBox(height: 10.0),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: shopNameController,
                        showCursor: true,
                        cursorColor: kTitleColor,
                        decoration: kInputDecoration.copyWith(
                          labelText: 'Shop Name',
                          labelStyle: kTextStyle.copyWith(color: kTitleColor),
                          hintText: 'Maan Shop',
                          hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                          enabledBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8.0)),
                            borderSide: BorderSide(color: kBorderColorTextField, width: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20.0),
                    Expanded(
                      child: FormField(
                        builder: (FormFieldState<dynamic> field) {
                          return InputDecorator(
                            decoration: const InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                                  borderSide: BorderSide(color: kBorderColorTextField, width: 2),
                                ),
                                contentPadding: EdgeInsets.all(7.0),
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                labelText: 'Business Category'),
                            child: DropdownButtonHideUnderline(child: getBusinessCategories()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: phoneNumberController,
                        showCursor: true,
                        cursorColor: kTitleColor,
                        decoration: kInputDecoration.copyWith(
                          labelText: 'Phone Number',
                          labelStyle: kTextStyle.copyWith(color: kTitleColor),
                          hintText: '017XXXXXXX',
                          hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                          enabledBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8.0)),
                            borderSide: BorderSide(color: kBorderColorTextField, width: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20.0),
                    Expanded(
                      child: TextField(
                        controller: emailController,
                        showCursor: true,
                        cursorColor: kTitleColor,
                        decoration: kInputDecoration.copyWith(
                          labelText: 'Email',
                          labelStyle: kTextStyle.copyWith(color: kTitleColor),
                          hintText: 'maansho@gmail.com',
                          hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                          enabledBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8.0)),
                            borderSide: BorderSide(color: kBorderColorTextField, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                Row(
                  children: [
                    Expanded(
                      child: FormField(
                        builder: (FormFieldState<dynamic> field) {
                          return InputDecorator(
                            decoration: const InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                                  borderSide: BorderSide(color: kBorderColorTextField, width: 2),
                                ),
                                contentPadding: EdgeInsets.all(7.0),
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                labelText: 'Package'),
                            child: DropdownButtonHideUnderline(child: getPackage()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 20.0),
                    Expanded(
                      child: FormField(
                        builder: (FormFieldState<dynamic> field) {
                          return InputDecorator(
                            decoration: const InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                                  borderSide: BorderSide(color: kBorderColorTextField, width: 2),
                                ),
                                contentPadding: EdgeInsets.all(7.0),
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                labelText: 'Payment Method'),
                            child: DropdownButtonHideUnderline(child: getMethod()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                Text(
                  'Logo',
                  style: kTextStyle.copyWith(color: kTitleColor),
                ),
                const SizedBox(height: 20.0),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      height: 70.0,
                      width: 70.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFBFE9FF)),
                        image: const DecorationImage(image: AssetImage('images/shoplogo.png'), fit: BoxFit.cover),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kBlueTextColor,
                        border: Border.all(
                          color: const Color(0xFFBFE9FF),
                        ),
                      ),
                      child: const Icon(FeatherIcons.camera, color: Colors.white, size: 14.0),
                    ),
                  ],
                ),
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
                        onTap: (() => Navigator.pop(context)),
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
