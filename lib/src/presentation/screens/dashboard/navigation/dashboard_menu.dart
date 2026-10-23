import 'package:flutter/material.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'dashboard_navigation.dart';

/// Secciones abiertas: los permisos compactan los elementos, sin huecos.
class DashboardMenu extends StatelessWidget {
  const DashboardMenu({
    super.key,
    required this.session,
    required this.onAction,
  });
  final SesionState session;
  final ValueChanged<DashboardAction> onAction;

  @override
  Widget build(BuildContext context) {
    final quick = dashboardQuickActions(session);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (quick.isNotEmpty) ...[
          const _Heading('Accesos rápidos'),
          LayoutBuilder(
            builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
              final columns = scale > 1.4 || constraints.maxWidth < 340 ? 2 : 3;
              final width =
                  (constraints.maxWidth - (columns - 1) * 8) / columns;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final action in quick)
                    SizedBox(
                      width: width,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: 104 * scale),
                        child: _QuickAction(
                          action: action,
                          onTap: () => onAction(action),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
        ],
        for (final group in dashboardGroups(session)) ...[
          _Heading(group.label),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                for (var i = 0; i < group.actions.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 52),
                  ListTile(
                    key: ValueKey('menu-${group.actions[i].name}'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: Icon(
                      group.actions[i].icon,
                      color: ColorSchema.primaryColor,
                    ),
                    title: Text(group.actions[i].label),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                    onTap: () => onAction(group.actions[i]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.action, required this.onTap});
  final DashboardAction action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final primary = action == DashboardAction.sale;
    return Material(
      color: primary ? ColorSchema.primaryColor : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: ValueKey('quick-${action.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                action.icon,
                color: primary ? Colors.white : ColorSchema.primaryColor,
                size: 25,
              ),
              const SizedBox(height: 8),
              Text(
                action == DashboardAction.loyalty
                    ? 'Fidelización'
                    : action.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primary ? Colors.white : const Color(0xFF353537),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
