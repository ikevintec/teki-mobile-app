import 'package:flutter/material.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'dashboard_navigation.dart';

class DashboardBottomBar extends StatelessWidget {
  const DashboardBottomBar({
    super.key,
    required this.destinations,
    required this.selected,
    required this.onSelected,
  });
  final List<DashboardDestination> destinations;
  final DashboardDestination selected;
  final ValueChanged<DashboardDestination> onSelected;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: Material(
        color: Colors.white,
        elevation: 5,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final destination in destinations)
              Expanded(
                child: Semantics(
                  selected: destination == selected,
                  button: true,
                  child: InkWell(
                    key: ValueKey('tab-${destination.name}'),
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => onSelected(destination),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 12,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            destination.icon,
                            size: 25,
                            color: destination == selected
                                ? ColorSchema.primaryColor
                                : Colors.black54,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            destination.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: destination == selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: destination == selected
                                  ? ColorSchema.primaryColor
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
