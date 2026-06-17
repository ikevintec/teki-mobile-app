import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

enum DismissibleActionType { edit, remision, guia, anular }

class DismissibleActionData {
  final DismissibleActionType type;
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onTap;

  const DismissibleActionData({
    required this.type,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.onTap,
  });
}

class DismissibleActionWidget extends StatelessWidget {
  final Widget child;
  final List<DismissibleActionData> actions;
  final VoidCallback? onDismissed;

  const DismissibleActionWidget({
    super.key,
    required this.child,
    required this.actions,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return child;
    }

    return Slidable(
      key: UniqueKey(),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.7, // 70% del ancho
        children: actions.map((action) => _buildSlidableAction(action)).toList(),
      ),
      child: child,
    );
  }

  SlidableAction _buildSlidableAction(DismissibleActionData action) {
    return SlidableAction(
      onPressed: (context) {
        action.onTap();
        // Cerrar el slidable después de la acción
        Slidable.of(context)?.close();
      },
      backgroundColor: action.backgroundColor,
      foregroundColor: Colors.white,
      icon: action.icon,
      label: action.label,
      spacing: 0,
    );
  }
}

// Función helper para crear acciones predefinidas para comprobantes
List<DismissibleActionData> createComprobanteActions({
  required VoidCallback? onEdit,
  required VoidCallback onRemision,
  required VoidCallback onGuia,
}) {
  return [
    if (onEdit != null)
      DismissibleActionData(
        type: DismissibleActionType.remision,
        label: 'Editar',
        icon: Icons.edit,
        backgroundColor: Colors.orange.shade600,
        onTap: onEdit,
      ),
    // DismissibleActionData(
    //   type: DismissibleActionType.edit,
    //   label: 'Remisión',
    //   icon: Icons.local_shipping,
    //   backgroundColor: Colors.blue.shade600,
    //   onTap: onEdit,
    // ),
  ];
}