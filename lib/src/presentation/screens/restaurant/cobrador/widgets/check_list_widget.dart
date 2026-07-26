import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/check.dart';
import 'package:teki_app/src/providers/restaurant/cobrador_provider.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'check_card_widget.dart';

class CheckListWidget extends ConsumerWidget {
  final int pvId;
  final List<Check> checks;
  final bool isLoading;
  final void Function(Check check, int index) onTap;

  const CheckListWidget({
    super.key,
    required this.pvId,
    required this.checks,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading && checks.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: ColorSchema.primaryColor),
      );
    }

    // El vacío también vive dentro del RefreshIndicator: se puede jalar
    // para refrescar aunque no haya cuentas (antes quedaba atrapado).
    return RefreshIndicator(
      color: ColorSchema.primaryColor,
      onRefresh: () => ref.read(cobradorProvider.notifier).init(pvId),
      child: checks.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 90),
                Icon(Icons.receipt_long_outlined,
                    size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'No hay cuentas con este filtro',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'Desliza hacia abajo para actualizar',
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 12),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(14),
              itemCount: checks.length,
              itemBuilder: (_, i) => CheckCardWidget(
                check: checks[i],
                index: i,
                onTap: () => onTap(checks[i], i),
              ),
            ),
    );
  }
}
