import 'package:flutter/material.dart';
import 'package:teki_app/src/data/models/teki_model/check.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/formats.dart';

class CheckCardWidget extends StatelessWidget {
  final Check check;
  final int index;
  final VoidCallback onTap;

  const CheckCardWidget({
    super.key,
    required this.check,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = check.items ?? [];
    final total = items.fold<double>(
        0, (s, d) => s + ((d.precioVenta ?? 0) * (d.cantidad ?? 1)));
    final hasMesa = check.pedido?.mesa != null;
    final mesaNum = check.pedido?.mesa?.numero;
    final tipo = check.pedido?.tipo;
    final createdOn = check.createdOn;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _TypeIcon(hasMesa: hasMesa, tipo: tipo),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${hasMesa ? 'Mesa $mesaNum' : _labelForTipo(tipo)} · #${formatOrderNumber(check.pedido?.id)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${items.length} items · S/. ${total.toStringAsFixed(2)}',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    if (createdOn != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _timeAgo(createdOn),
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (check.pagado == true)
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 18),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _labelForTipo(String? tipo) {
    switch (tipo) {
      case 'LOCAL':
        return 'Pedido local';
      case 'PEDIDO_LOCAL':
        return 'Pedido';
      case 'PEDIDO_LOCAL_INTERNO':
        return 'Pedido interno';
      case 'PEDIDO_FORANEO':
        return 'Envío foráneo';
      case 'PEDIDO_ONLINE':
        return 'Pedido online';
      default:
        return 'Pedido';
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} días';
  }
}

class _TypeIcon extends StatelessWidget {
  final bool hasMesa;
  final String? tipo;

  const _TypeIcon({required this.hasMesa, this.tipo});

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;

    if (hasMesa) {
      icon = Icons.table_restaurant;
      color = ColorSchema.primaryColor;
    } else if (tipo == 'PEDIDO_FORANEO' || tipo == 'PEDIDO_ONLINE') {
      icon = Icons.delivery_dining;
      color = Colors.orange;
    } else {
      icon = Icons.receipt_long;
      color = Colors.teal;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
