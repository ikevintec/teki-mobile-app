import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/people_model/biller_list_model.dart';
import 'package:teki_app/src/presentation/screens/biller/biller_sections/update_biller_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/delete_toast.dart';

class BillerListSection extends StatefulWidget {
  const BillerListSection({
    super.key,
  });

  @override
  State<BillerListSection> createState() => _BillerListSectionState();
}

class _BillerListSectionState extends State<BillerListSection> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: billerListModel.length,
      itemBuilder: (context, index) {
        final biller = billerListModel[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    Expanded(
                      child: Text(
                        biller["name"],
                        style: GoogleFonts.raleway(
                          color: const Color(0xFF5D6571),
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            "assets/icons/icon_svg/biller_code.svg",
                            width: 18,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Text(
                            biller["billerCode"],
                            style: GoogleFonts.roboto(
                              color: const Color(0xFF5D6571),
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 15,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      size: 20,
                      color: Color(0xFFA0A0A3),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: Text(
                        biller["email"],
                        style: GoogleFonts.roboto(
                          color: const Color(0xFFA0A0A3),
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8,
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
                    Expanded(
                      child: Text(
                        biller["phone"],
                        style: GoogleFonts.roboto(
                          color: const Color(0xFFA0A0A3),
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              "assets/icons/icon_svg/location_icon.svg",
                              width: 18,
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              child: Text(
                                biller["address"],
                                style: GoogleFonts.roboto(
                                    color: const Color(0xFF5D6571),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                              buildModalBottomSheet(context, biller);
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
                                  context, biller["name"]);
                              setState(() {
                                billerListModel.removeAt(index);
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

  void buildModalBottomSheet(BuildContext context, biller) {
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
          height: MediaQuery.of(context).size.height * 0.9,
          child: UpdateBillerSection(biller: biller),
        );
      },
    );
  }
}
