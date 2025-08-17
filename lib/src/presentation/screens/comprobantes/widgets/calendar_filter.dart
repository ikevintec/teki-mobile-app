import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/utils/contstants.dart';

enum CalendarFilter { day, week, month, year, custom }

class CustomDatePicker extends StatefulWidget {
  final Function(DateTimeRange) onDateSelected;
  const CustomDatePicker({super.key, required this.onDateSelected});

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  CalendarFilter _selectedFilter = CalendarFilter.day;
  DateTimeRange? _selectedRange;

  List<DateTimeRange> getCurrentList() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedFilter) {
      case CalendarFilter.day:
        return List.generate(14, (i) {
          final date = today.subtract(Duration(days: i));
          return DateTimeRange(start: date, end: date);
        });
      case CalendarFilter.week:
        return List.generate(10, (i) {
          final startOfWeek =
              today.subtract(Duration(days: today.weekday - 1 + i * 7));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          return DateTimeRange(start: startOfWeek, end: endOfWeek);
        });
      case CalendarFilter.month:
        return List.generate(now.month, (i) {
          final firstDay = DateTime(now.year, i + 1, 1);
          final lastDay = DateTime(now.year, i + 2, 0);
          return DateTimeRange(start: firstDay, end: lastDay);
        });

      case CalendarFilter.year:
        final firstDay = DateTime(now.year, 1, 1);
        final lastDay = DateTime(now.year, 12, 31);
        return [DateTimeRange(start: firstDay, end: lastDay)];
      case CalendarFilter.custom:
        return _selectedRange != null ? [_selectedRange!] : [];
    }
  }

  String formatRange(DateTimeRange range) {
    final format = DateFormat('dd MMM yyyy', 'es');
    return '${format.format(range.start)} - ${format.format(range.end)}';
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('es'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ColorSchema.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
              onSurfaceVariant: Colors.white,
              outline: Colors.white,
              secondary: ColorSchema.primaryColor.withOpacity(0.2),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: ColorSchema.primaryColor,
              dayStyle: TextStyle(color: Colors.black87),
              headerBackgroundColor: ColorSchema.primaryColor,
              rangePickerBackgroundColor:
                  const Color.fromARGB(255, 240, 240, 240),
              rangePickerHeaderBackgroundColor: ColorSchema.primaryColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: ColorSchema.primaryColor,
              ),
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.black87),
              bodySmall: TextStyle(color: Colors.black87),
              bodyLarge: TextStyle(color: Colors.white),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedFilter = CalendarFilter.custom;
        _selectedRange = picked;
      });
      widget.onDateSelected(picked);
    }
  }

  void _showFilterSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 30, vertical: 30), // Margen a todo el bloque
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: CalendarFilter.values.map((filter) {
              final label = {
                CalendarFilter.day: 'Hoy',
                CalendarFilter.week: 'Últimas semanas',
                CalendarFilter.month: 'Mes actual',
                CalendarFilter.year: 'Año actual',
                CalendarFilter.custom: 'Fecha personalizada',
              }[filter]!;

              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: Text(
                  label,
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: _selectedFilter == filter
                    ? const Icon(Icons.check,
                        color: ColorSchema.primaryColor, size: 20)
                    : null,
                onTap: () async {
                  Navigator.pop(context);
                  if (filter == CalendarFilter.custom) {
                    await _pickCustomDateRange();
                  } else {
                    setState(() {
                      _selectedFilter = filter;

                      // Selecciona el último rango (última fecha a la derecha)
                      final opciones = getCurrentList();
                      final dateOptions =
                          _selectedFilter == CalendarFilter.month
                              ? opciones
                              : opciones.reversed.toList();
                      _selectedRange =
                          dateOptions.isNotEmpty ? dateOptions.last : null;

                      // Notifica que cambió
                      if (_selectedRange != null) {
                        widget.onDateSelected(_selectedRange!);
                      }
                    });

                    _scrollToEnd();
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    final opciones = getCurrentList();
    final dateOptions = _selectedFilter == CalendarFilter.month
        ? opciones
        : opciones.reversed.toList();

    _selectedRange = dateOptions.isNotEmpty ? dateOptions.last : null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedRange != null) {
        widget.onDateSelected(_selectedRange!);
      }

      _scrollToEnd();
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final options = getCurrentList();
    final dateOptions = _selectedFilter == CalendarFilter.month
        ? options
        : options.reversed.toList();

    return Container(
      // color: ColorSchema.primaryColor,
      padding: const EdgeInsets.only(bottom: 0, top: 0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 50,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: dateOptions.length,
                itemBuilder: (context, index) {
                  final item = dateOptions[index];
                  final isSelected = _selectedRange == item;
                  final text = {
                    CalendarFilter.day:
                        DateFormat('dd MMM', 'es').format(item.start),
                    CalendarFilter.week:
                        '${DateFormat('dd MMM', 'es').format(item.start)} - ${DateFormat('dd MMM', 'es').format(item.end)}',
                    CalendarFilter.month: DateFormat('MMMM', 'es')
                        .format(item.start)
                        .toUpperCase(),
                    CalendarFilter.year: '${item.start.year}',
                    CalendarFilter.custom:
                        '${DateFormat('dd MMM', 'es').format(item.start)} - ${DateFormat('dd MMM', 'es').format(item.end)}',
                  }[_selectedFilter]!;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRange = item;
                      });
                      widget.onDateSelected(item);
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: isSelected
                              ? ColorSchema.primaryColor
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: BoxBorder.all(color: Colors.white)),
                      child: Center(
                        child: Text(
                          text,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.calendar_month,
              color: ColorSchema.primaryColor,
            ),
            onPressed: _showFilterSelector,
          ),
        ],
      ),
    );
  }
}
