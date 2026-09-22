import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/screens/kitchen/widgets/kitchen_board.dart';
import 'package:teki_app/src/presentation/screens/kitchen/widgets/kitchen_filter_sheet.dart';
import 'package:teki_app/src/presentation/screens/kitchen/widgets/kitchen_undo_bar.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/kitchen/kitchen_provider.dart';
import 'package:teki_app/src/providers/kitchen/kitchen_state.dart';
import 'package:teki_app/src/utils/constants.dart';

class KitchenMainScreen extends ConsumerStatefulWidget {
  const KitchenMainScreen({super.key});

  @override
  ConsumerState<KitchenMainScreen> createState() => _KitchenMainScreenState();
}

class _KitchenMainScreenState extends ConsumerState<KitchenMainScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final session = ref.read(sesionProvider);
      ref
          .read(kitchenProvider.notifier)
          .initialize(
            officeId: session.office?.id ?? 0,
            officeCode: session.office?.codigo ?? '',
          );
    });
  }

  void _openFilters(KitchenState state) {
    KitchenFilterSheet.show(
      context,
      filters: state.filters,
      productionAreas: state.productionAreas,
      onApply: (filters) {
        final notifier = ref.read(kitchenProvider.notifier);
        notifier.setPreparationMinutes(filters.preparationMinutes);
        notifier.setSoundEnabled(filters.soundEnabled);
        notifier.setAlertTone(filters.alertTone);
        notifier.setLateAlertEnabled(filters.lateAlertEnabled);
        notifier.setShowCancelled(filters.showCancelled);
        notifier.setProductionAreas(filters.productionAreaIds);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kitchenProvider);
    ref.listen<String?>(kitchenProvider.select((value) => value.errorMessage), (
      previous,
      next,
    ) {
      if (next == null || next == previous) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(next),
            action: SnackBarAction(
              label: 'Cerrar',
              onPressed: ref.read(kitchenProvider.notifier).clearError,
            ),
          ),
        );
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: ColorSchema.primaryColor,
        backgroundColor: ColorSchema.primaryColor,
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: Get.back,
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const Icon(
              Icons.soup_kitchen_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Cocina',
              style: GoogleFonts.raleway(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 10),
            Tooltip(
              message: state.socketConnected
                  ? 'En vivo: las comandas llegan al instante'
                  : 'Sin conexión en vivo: se actualiza cada minuto',
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state.socketConnected
                      ? const Color(0xFF4ADE80)
                      : const Color(0xFFFCA5A5),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: state.filters.soundEnabled
                ? 'Silenciar avisos'
                : 'Activar avisos',
            onPressed: () => ref
                .read(kitchenProvider.notifier)
                .setSoundEnabled(!state.filters.soundEnabled),
            icon: Icon(
              state.filters.soundEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: Colors.white,
            ),
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: state.isRefreshing
                ? null
                : () => ref.read(kitchenProvider.notifier).refresh(),
            icon: state.isRefreshing
                ? const SizedBox.square(
                    dimension: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Filtros y ajustes',
            onPressed: () => _openFilters(state),
            icon: const Icon(Icons.tune_rounded, color: Colors.white),
          ),
        ],
      ),
      body: const SafeArea(top: false, child: KitchenBoard()),
      bottomNavigationBar: KitchenUndoBar(action: state.undoAction),
    );
  }
}
