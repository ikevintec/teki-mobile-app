import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/screens/products/products_sections/update_product_screen.dart';
import 'package:teki_app/src/presentation/widgets/toast/delete_toast.dart';

class ProductListSection extends StatefulWidget {
  final dynamic isSmallScreen;
  final dynamic productList;

  const ProductListSection(
      {super.key, required this.isSmallScreen, required this.productList});

  @override
  State<ProductListSection> createState() => _ProductListSectionState();
}

class _ProductListSectionState extends State<ProductListSection> {
  @override
  Widget build(BuildContext context) {
    if (widget.productList.isEmpty) {
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
            "No Product Found",
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
          itemCount: widget.productList.length,
          itemBuilder: (context, index) {
            final product = widget.productList[index];
            return Card(
              elevation: 0,
              color: Colors.white,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      product["product-image"]!,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product["name"]!,
                          style: GoogleFonts.raleway(
                            textStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: widget.isSmallScreen ? 16 : 18,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Padding(
                            padding: const EdgeInsets.only(bottom: 8, top: 6),
                            child: Text(
                              product["category"]!,
                              style: GoogleFonts.raleway(
                                textStyle: const TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Stock: ${product["stock"]}",
                                style: GoogleFonts.nunito(),
                              ),
                              const SizedBox(
                                height: 2,
                              ),
                              Text(
                                "Price: \$${product["price"]}",
                                style: GoogleFonts.nunito(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Row(
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
                              buildModalBottomSheet(context, product);
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
                              DeleteToast.showDeleteToast(
                                  context, product["name"]);
                              setState(() {
                                widget.productList.removeAt(index);
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
                  )
                ],
              ),
            );
          },
        ),
      );
    }
  }

  void buildModalBottomSheet(BuildContext context, product) {
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
          child: UpdateProductScreen(product: product),
        );
      },
    );
  }
}
