import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/warehouse_model/warehouse_model.dart';
import 'package:teki_app/src/presentation/screens/warehouse/warehouse_sections/update_warehouse_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/delete_toast.dart';

class WarehouseListSection extends StatefulWidget {
  const WarehouseListSection({
    super.key,
  });

  @override
  State<WarehouseListSection> createState() => _WarehouseListSectionState();
}

class _WarehouseListSectionState extends State<WarehouseListSection> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: warehouseModel.length,
      itemBuilder: (context, index) {
        final warehouseData = warehouseModel[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 24),
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
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.store_mall_directory,
                            color: Colors.blue.shade300, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${warehouseData["warehouse"]}",
                            style: GoogleFonts.raleway(
                              color: const Color(0xFF5D6571),
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.phone,
                            color: Colors.blue.shade300, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "${warehouseData["phone"]}",
                          style: GoogleFonts.nunito(
                            color: const Color(0xFFA0A0A3),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.email,
                            color: Colors.blue.shade300, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "${warehouseData["email"]}",
                          style: GoogleFonts.nunito(
                            color: const Color(0xFFA0A0A3),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            color: Colors.blue.shade300, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${warehouseData["address"]}",
                            style: GoogleFonts.nunito(
                              color: const Color(0xFFA0A0A3),
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
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
                        buildModalBottomSheet(context, warehouseData);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
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
                            context, warehouseData["warehouse"]);
                        setState(() {
                          warehouseModel.removeAt(index);
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
            ],
          ),
        );
      },
    );
  }

  void buildModalBottomSheet(BuildContext context, warehouse) {
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
          child: UpdateWarehouseSection(warehouse: warehouse),
        );
      },
    );
  }
}
