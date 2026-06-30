import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/screens/expense_category/expense_category_sections/expense_category_update_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/delete_toast.dart';

class ExpenseCategoryListSection extends StatefulWidget {
  final dynamic isSmallScreen;
  final dynamic categoryList;

  const ExpenseCategoryListSection(
      {super.key, required this.isSmallScreen, required this.categoryList});

  @override
  State<ExpenseCategoryListSection> createState() =>
      _ExpenseCategoryListSectionState();
}

class _ExpenseCategoryListSectionState
    extends State<ExpenseCategoryListSection> {
  @override
  Widget build(BuildContext context) {
    if (widget.categoryList.isEmpty) {
      return Expanded(
          child: Center(
              child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            "assets/images/other/empty_product.png",
            width: 350,
          ),
          Text(
            "No Category Found",
            style: GoogleFonts.raleway(
                fontWeight: FontWeight.w500,
                fontSize: 24,
                color: const Color(0xFF333333)),
          )
        ],
      )));
    } else {
      return Expanded(
        child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: widget.categoryList.length,
            itemBuilder: (context, index) {
              final category = widget.categoryList[index];
              return Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      category["category-name"],
                      style: GoogleFonts.raleway(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: const Color(0xFF444444),
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(
                        top: 10,
                      ),
                      child: Text(
                        category["subCategory-name"],
                        style: GoogleFonts.roboto(),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: Colors.blue.shade50.withOpacity(0.3),
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
                              buildModalBottomSheet(context, category);
                            },
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: Colors.red.shade50.withOpacity(0.3),
                          ),
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                DeleteToast.showDeleteToast(
                                    context, category["category-name"]);
                                widget.categoryList.removeAt(index);
                              });
                            },
                            icon: SvgPicture.asset(
                              "assets/icons/icon_svg/delete_icon.svg",
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFFE2E4E7))
                ],
              );
            }),
      );
    }
  }

  void buildModalBottomSheet(BuildContext context, category) {
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
          height: MediaQuery.of(context).size.height * 0.8,
          child: ExpenseCategoryUpdateSection(category: category),
        );
      },
    );
  }
}
