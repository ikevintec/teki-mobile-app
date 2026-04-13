import 'package:flutter/material.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/utils/contstants.dart';

class DatePicker extends StatefulWidget {
  final String labelText;
  final String hintText;

  const DatePicker(
      {super.key, required this.labelText, required this.hintText});

  @override
  State<DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  late DateTime _selectedDay;
  late TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _dateController = TextEditingController();
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _dateController,
      onTap: () {
        _selectDate(context, _selectedDay, _dateController);
      },
      readOnly: true,
      decoration: InputDecoration(
        suffixIcon: IconButton(
          onPressed: () {
            _selectDate(context, _selectedDay, _dateController);
          },
          icon: SvgPicture.asset(
            "assets/icons/icon_svg/calendar.svg",
            width: 20,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        labelText: widget.labelText,
        labelStyle: GoogleFonts.raleway(
          color: const Color(0xFF444444),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        fillColor: Colors.white,
        filled: true,
        hintText: widget.hintText,
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
        _selectedDay = picked;
        controller.text = '${picked.month}/${picked.day}/${picked.year}';
      });
    }
  }
}
