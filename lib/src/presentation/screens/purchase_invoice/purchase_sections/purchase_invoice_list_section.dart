import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/invoice_model/purchase_invoice_model.dart';
import 'package:teki_app/src/presentation/screens/purchase_invoice/purchase_sections/update_purchase_invoice_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/delete_toast.dart';

class PurchaseInvoiceListSection extends StatefulWidget {
  const PurchaseInvoiceListSection({
    super.key,
  });

  @override
  State<PurchaseInvoiceListSection> createState() =>
      _PurchaseInvoiceListSectionState();
}

class _PurchaseInvoiceListSectionState
    extends State<PurchaseInvoiceListSection> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: purchaseInvoiceModel.length,
      itemBuilder: (context, index) {
        final purchaseInvoice = purchaseInvoiceModel[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(purchaseInvoice["customerName"],
                        style: GoogleFonts.raleway(
                          color: const Color(0xFF5D6571),
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        )),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 10),
                      decoration: BoxDecoration(
                        color: Color(purchaseInvoice["paymentStatusColor"]),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(purchaseInvoice["paymentStatus"],
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 15,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.phone_android_sharp,
                      size: 20,
                      color: Color(0xFFA0A0A3),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Text(
                      purchaseInvoice["customerPhone"],
                      style: GoogleFonts.nunito(
                        color: const Color(0xFFA0A0A3),
                        fontSize: 16,
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
                Row(
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
                      purchaseInvoice["date"],
                      style: GoogleFonts.nunito(
                        color: const Color(0xFFA0A0A3),
                        fontSize: 16,
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3.0),
                          child: SvgPicture.asset(
                            "assets/icons/icon_svg/company_icon.svg",
                            width: 18,
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Text(
                          purchaseInvoice["company"],
                          style: GoogleFonts.nunito(
                              color: const Color(0xFF5D6571),
                              fontWeight: FontWeight.w600,
                              fontSize: 15),
                        )
                      ],
                    ),
                    Row(
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
                              buildModalBottomSheet(context, purchaseInvoice);
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
                                  context, purchaseInvoice["customerName"]);
                              setState(() {
                                purchaseInvoiceModel.removeAt(index);
                              });
                            },
                            icon: SvgPicture.asset(
                              "assets/icons/icon_svg/delete_icon.svg",
                              color: Colors.red,
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void buildModalBottomSheet(BuildContext context, purchaseInvoice) {
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
          height: MediaQuery.of(context).size.height * 0.65,
          child: UpdatePurchaseInvoiceSection(purchaseInvoice: purchaseInvoice),
        );
      },
    );
  }
}
