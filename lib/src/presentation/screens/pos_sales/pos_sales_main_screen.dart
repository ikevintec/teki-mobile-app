import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/products_model/product_brand_model.dart';
import 'package:teki_app/src/data/models/products_model/product_list_model.dart';
import 'package:teki_app/src/presentation/screens/pos_sales/pos_sales_sections/pos_bills_section.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/utils/constants.dart';

class POSSalesMainScreen extends StatefulWidget {
  const POSSalesMainScreen({super.key});

  @override
  State<POSSalesMainScreen> createState() => _POSSalesMainScreenState();
}

class _POSSalesMainScreenState extends State<POSSalesMainScreen> {
  String categorySelectedValue = "All";
  String searchQuery = "";
  String selectBrand = "";
  List<Map> selectedItems = [];
  List<Map> featuredProductList = [];
  List<String> categoryItems = [
    "All",
    "Fashion",
    "Gadget",
    "Cosmetics",
    "Food",
    "Fruit",
    "Computer",
    "Electronics"
  ];

  bool isCategoryDropdownOpen = false;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredProducts = productListModel;

    if (categorySelectedValue != "All") {
      featuredProductList.clear();
      filteredProducts = filteredProducts
          .where((product) => product["category"] == categorySelectedValue)
          .toList();
      categorySelectedValue = "All";
    }

    if (selectBrand.isNotEmpty) {
      featuredProductList.clear();
      filteredProducts = filteredProducts
          .where((product) => product["Brand"] == selectBrand)
          .toList();
      Navigator.pop(context);
      selectBrand = "";
    }

    if (searchQuery.isNotEmpty) {
      featuredProductList.clear();
      filteredProducts = filteredProducts.where((product) {
        return product["name"]
            .toLowerCase()
            .contains(searchQuery.toLowerCase());
      }).toList();
      searchQuery = "";
    }

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(
          navigateName: "POS Sales",
        ),
      ),
      body: Container(
        color: Colors.white70,
        child: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search Product",
                  hintStyle: GoogleFonts.roboto(
                      textStyle: const TextStyle(color: Colors.grey)),
                  suffixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: ColorSchema.primaryColor, width: 1),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  buildElevatedButton("Category", const Color(0xFF2C6AE5)),
                  buildElevatedButton("Brand", const Color(0xFF32C98D)),
                  buildElevatedButton("Featured", const Color(0xFFFF9720)),
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              "Select POS Items",
              textAlign: TextAlign.center,
              style: GoogleFonts.raleway(fontWeight: FontWeight.w600),
            ),
            const SizedBox(
              height: 20,
            ),
            filteredProducts.isEmpty
                ? const Expanded(
                    child: Center(
                      child: Text(
                        'No products found.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: featuredProductList.isEmpty
                            ? filteredProducts.length
                            : featuredProductList.length,
                        itemBuilder: (context, index) {
                          final product = featuredProductList.isEmpty
                              ? filteredProducts[index]
                              : featuredProductList[index];
                          final isSelected = selectedItems.contains(product);

                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectedItems.remove(product);
                                } else {
                                  selectedItems.add(product);
                                }
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      product["product-image"],
                                      width: MediaQuery.of(context).size.width *
                                          0.2,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(7.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Center(
                                          child: Text(
                                            product["name"],
                                            style: GoogleFonts.raleway(
                                              textStyle: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Center(
                                          child: Text(
                                            product["barcode"],
                                            style: GoogleFonts.roboto(
                                              textStyle: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
            const SizedBox(
              height: 20,
            )
          ],
        ),
      ),
      floatingActionButton: selectedItems.isNotEmpty
          ? Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton.extended(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              PosBillsSection(product: selectedItems)));
                },
                label: Text(
                  "Go POS Bills",
                  style: GoogleFonts.raleway(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                backgroundColor:
                    ColorSchema.primaryColor, // Adjust color as needed
              ),
            )
          : null,
    );
  }

  ElevatedButton buildElevatedButton(
    String buttonName,
    Color bgColor,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))),
      onPressed: () {
        if (buttonName == "Brand") {
          buildBrandModal(context);
        }
        if (buttonName == "Featured") {
          final featureItem = productListModel
              .where((item) => item["featured"] == true)
              .toList();
          setState(() {
            featuredProductList = featureItem;
          });
        }
        if (buttonName == "Category") {
          openCategoryDropdown(context);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Text(
          buttonName,
          style: GoogleFonts.raleway(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }

  void buildBrandModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Brands",
                    style: GoogleFonts.raleway(
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Color(0xFF444444),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: Colors.red, width: 1)),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: SvgPicture.asset(
                            "assets/icons/icon_svg/close_icon.svg",
                            width: 10,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 30,
              ),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: productBrandModel.length,
                  itemBuilder: (context, index) {
                    final brand = productBrandModel[index];
                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectBrand = brand["brand-name"];
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.blue.shade100,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                brand["brand-image"],
                                width: MediaQuery.of(context).size.width * 0.2,
                              ),
                            ),
                            Center(
                              child: Text(
                                brand["brand-name"],
                                style: GoogleFonts.raleway(
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void openCategoryDropdown(BuildContext context) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(20.0, 225.0, 100.0, 0),
      elevation: 0,
      popUpAnimationStyle: AnimationStyle(
        reverseDuration: const Duration(milliseconds: 500),
        duration: const Duration(milliseconds: 500),
      ),
      color: Colors.white,
      items: categoryItems.map((String item) {
        return PopupMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
    ).then((selectedValue) {
      if (selectedValue != null) {
        setState(() {
          categorySelectedValue = selectedValue;
        });
      }
    });
  }
}
