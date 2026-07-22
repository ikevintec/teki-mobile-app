import 'package:flutter/material.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/utils/constants.dart';

class StartEndDatePickerSection extends StatefulWidget {
  const StartEndDatePickerSection({super.key});

  @override
  State<StartEndDatePickerSection> createState() =>
      _StartEndDatePickerSectionState();
}

class _StartEndDatePickerSectionState extends State<StartEndDatePickerSection> {
  late DateTime _startSelectedDay;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;

  @override
  void initState() {
    super.initState();
    _startSelectedDay = DateTime.now();
    _startDateController = TextEditingController();
    _endDateController = TextEditingController();
  }

  @override
  void dispose() {
    _startDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: buildTextField(context, "Start Date", _startDateController)),
        const SizedBox(
          width: 10,
        ),
        Expanded(child: buildTextField(context, "End Date", _endDateController))
      ],
    );
  }

  TextField buildTextField(BuildContext context, String labelText,
      TextEditingController controller) {
    return TextField(
      controller: controller,
      onTap: () {
        _selectDate(context, _startSelectedDay, controller);
      },
      readOnly: true,
      decoration: InputDecoration(
        suffixIcon: IconButton(
          onPressed: () {
            _selectDate(context, _startSelectedDay, controller);
          },
          icon: SvgPicture.asset(
            "assets/icons/icon_svg/calendar.svg",
            width: 20,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        labelText: labelText,
        labelStyle: GoogleFonts.raleway(
          color: const Color(0xFF444444),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        fillColor: Colors.white,
        filled: true,
        hintText: "MM/DD/YYYY",
        hintStyle: GoogleFonts.roboto(
          textStyle: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E4E7), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: ColorSchema.primaryColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      keyboardType: TextInputType.number,
    );
  }

  Future<void> _selectDate(BuildContext context, DateTime selectedDate,
      TextEditingController controller) async {
    final DateTime? picked = await showRoundedDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.utc(2020, 1, 1),
      lastDate: DateTime.utc(2030, 12, 31),
      borderRadius: 12,
      height: MediaQuery.of(context).size.height * 0.35,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(primary: ColorSchema.primaryColor),
      ),
      styleDatePicker: MaterialRoundedDatePickerStyle(
        textStyleYearButton: const TextStyle(
          color: Colors.white70,
          fontSize: 20,
        ),
        textStyleDayButton: GoogleFonts.roboto(
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        paddingDatePicker: const EdgeInsets.all(10),
        textStyleButtonPositive: const TextStyle(
            color: ColorSchema.primaryColor,
            fontSize: 16,
            fontWeight: FontWeight.bold),
        textStyleButtonNegative: GoogleFonts.roboto(
          textStyle: const TextStyle(
            color: ColorSchema.primaryColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundHeader: ColorSchema.primaryColor,
        textStyleButtonAction: const TextStyle(
          color: Colors.white,
          fontSize: 18,
        ),
        textStyleCurrentDayOnCalendar: const TextStyle(
          color: ColorSchema.primaryColor,
          fontSize: 16,
        ),
        textStyleDayOnCalendarSelected: GoogleFonts.roboto(
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        _startSelectedDay = picked;
        controller.text = '${picked.month}/${picked.day}/${picked.year}';
      });
    }
  }
}
