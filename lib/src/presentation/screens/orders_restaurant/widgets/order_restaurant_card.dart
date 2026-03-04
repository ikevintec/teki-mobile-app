import 'package:flutter/material.dart';
import 'package:teki_app/src/data/models/teki_model/orderRestaurant.dart';
import 'package:teki_app/src/utils/contstants.dart';

class OrderRestaurantCard extends StatelessWidget {
  final OrderRestaurant order;

  const OrderRestaurantCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildOrderNumber(),
                const Spacer(),
                _buildEstadoBadge(),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.receipt_long_outlined,
                  label: _comandaLabel(),
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.table_restaurant_outlined,
                  label: _mesaLabel(),
                ),
                const SizedBox(width: 8),
                _buildTipoBadge(),
              ],
            ),
            if (order.nombreCliente != null &&
                order.nombreCliente!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 14, color: ColorSchema.subTitleTextColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.nombreCliente!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ColorSchema.subTitleTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderNumber() {
    return Text(
      'Orden #${order.numeroOrden ?? order.id ?? '-'}',
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: ColorSchema.titleTextColor,
      ),
    );
  }

  Widget _buildEstadoBadge() {
    final config = _estadoConfig(order.estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: config.$1.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.$1.withValues(alpha: 0.4)),
      ),
      child: Text(
        config.$2,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: config.$1,
        ),
      ),
    );
  }

  Widget _buildTipoBadge() {
    final label = _tipoLabel(order.tipo);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ColorSchema.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: ColorSchema.primaryColor,
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: ColorSchema.subTitleTextColor),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: ColorSchema.subTitleTextColor,
          ),
        ),
      ],
    );
  }

  String _comandaLabel() {
    final numero = order.comandas?.isNotEmpty == true
        ? order.comandas!.first.numeroComanda
        : null;
    return numero != null ? 'Comanda #$numero' : 'Sin comanda';
  }

  String _mesaLabel() {
    final numero = order.mesa?.numero?.toString();
    return numero != null ? 'Mesa $numero' : 'Sin mesa';
  }

  String _tipoLabel(String? tipo) {
    switch (tipo) {
      case 'LOCAL':
        return 'Mesa';
      case 'PEDIDO_LOCAL_INTERNO':
        return 'Interno';
      case 'PEDIDO_LOCAL':
        return 'Para llevar';
      case 'PEDIDO_FORANEO':
        return 'Delivery';
      case 'PEDIDO_ONLINE':
        return 'Online';
      default:
        return tipo ?? '-';
    }
  }

  (Color, String) _estadoConfig(String? estado) {
    switch (estado) {
      case 'PENDIENTE':
        return (Colors.orange, 'Pendiente');
      case 'PREPARADO':
        return (Colors.blue, 'Preparado');
      case 'PRECUENTA':
        return (Colors.purple, 'Pre-cuenta');
      case 'FINALIZADO':
        return (Colors.green, 'Finalizado');
      case 'CANCELADO':
        return (Colors.red, 'Cancelado');
      default:
        return (Colors.grey, estado ?? '-');
    }
  }
}
