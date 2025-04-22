import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/purchase_model/purchase_return_model.dart';
import 'package:teki_app/src/presentation/screens/purchase/purchase_sections/edit_purchase_return_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/delete_toast.dart';

class PurchaseReturnListSection extends StatefulWidget {
  const PurchaseReturnListSection({super.key});

  @override
  State<PurchaseReturnListSection> createState() =>
      _PurchaseReturnListSectionState();
}

class _PurchaseReturnListSectionState extends State<PurchaseReturnListSection> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: purchaseReturnModel.length,
      itemBuilder: (context, index) {
        final purchase = purchaseReturnModel[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 0,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(purchase["supplierName"],
                          style: GoogleFonts.raleway(
                            color: const Color(0xFF5D6571),
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          )),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              "assets/icons/icon_svg/remark_icon.svg",
                              width: 18,
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Text(purchase["remark"],
                                style: GoogleFonts.nunito(
                                    color: const Color(0xFF5D6571),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15))
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.date_range_outlined,
                        size: 20,
                        color: Color(0xFFA0A0A3),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Text(
                        purchase["date"],
                        style: GoogleFonts.nunito(
                          color: const Color(0xFFA0A0A3),
                          fontSize: 16,
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: SvgPicture.asset(
                          "assets/icons/icon_svg/warehouse.svg",
                          color: const Color(0xFFA0A0A3),
                          width: 16,
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 2.0),
                        child: Text(
                          purchase["warehouse"],
                          style: GoogleFonts.nunito(
                            color: const Color(0xFFA0A0A3),
                            fontSize: 16,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: SvgPicture.asset(
                          "assets/icons/icon_svg/reference_icon.svg",
                          color: const Color(0xFFA0A0A3),
                          width: 16,
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 2.0),
                        child: Text(
                          purchase["reference"],
                          style: GoogleFonts.nunito(
                            color: const Color(0xFFA0A0A3),
                            fontSize: 16,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 7.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset(
                            "assets/icons/icon_svg/dollar_icon.svg",
                            width: 28,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Text(
                            purchase["amount"],
                            style: GoogleFonts.nunito(
                                color: const Color(0xFF5D6571),
                                fontWeight: FontWeight.w600,
                                fontSize: 18),
                          )
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Row(
                          children: [
                            Container(
                              width: 35,
                              height: 35,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: Colors.blue.shade50.withOpacity(0.5),
                              ),
                              child: IconButton(
                                icon: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: SvgPicture.asset(
                                    "assets/icons/icon_svg/edit_icon.svg",
                                    color: Colors.blue,
                                  ),
                                ),
                                onPressed: () {
                                  buildModalBottomSheet(context, purchase);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 35,
                              height: 35,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: Colors.red.shade50.withOpacity(0.5),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  DeleteToast.showDeleteToast(
                                      context, purchase["supplierName"]);
                                  setState(() {
                                    purchaseReturnModel.removeAt(index);
                                  });
                                },
                                icon: SvgPicture.asset(
                                  "assets/icons/icon_svg/delete_icon.svg",
                                  color: Colors.red,
                                ),
                              ),
                            )
                          ],
                        ),
                      )
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

  void buildModalBottomSheet(BuildContext context, purchase) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      elevation: 0,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      context: context,
      builder: (_) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: EditPurchaseReturnSection(purchase: purchase),
        );
      },
    );
  }
}
