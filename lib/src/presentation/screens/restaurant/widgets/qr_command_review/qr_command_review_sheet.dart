import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/presentation/screens/restaurant/widgets/qr_command_review/qr_command_review_card.dart';
import 'package:teki_app/src/providers/restaurant/qr_command_review_provider.dart';
import 'package:teki_app/src/utils/constants.dart';

class QrCommandReviewSheet extends ConsumerStatefulWidget {
  const QrCommandReviewSheet({super.key});

  @override
  ConsumerState<QrCommandReviewSheet> createState() =>
      _QrCommandReviewSheetState();
}

class _QrCommandReviewSheetState extends ConsumerState<QrCommandReviewSheet> {
  late bool _hadCommands;

  @override
  void initState() {
    super.initState();
    _hadCommands = ref.read(qrCommandReviewProvider).pendingCommands.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(
      qrCommandReviewProvider.select((state) => state.pendingCommands.length),
      (previous, next) {
        if (next > 0) _hadCommands = true;
        if (_hadCommands && next == 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
        }
      },
    );

    final state = ref.watch(qrCommandReviewProvider);
    final notifier = ref.read(qrCommandReviewProvider.notifier);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.86,
      child: Column(
        children: [
          Container(
            width: 42,
            height: 4,
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 8, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Color(0xFFB45309),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comandas por QR (${state.pendingCommands.length})',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Cocina las verá después de que las apruebes.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar cola',
                  onPressed: state.isRefreshing ? null : notifier.refresh,
                  color: ColorSchema.primaryColor,
                  icon: state.isRefreshing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (state.errorMessage != null)
            Container(
              width: double.infinity,
              color: const Color(0xFFFFF1F2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Row(
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 18,
                    color: Color(0xFFB91C1C),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFF991B1B),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: notifier.refresh,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: state.isLoading && state.pendingCommands.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: ColorSchema.primaryColor,
                    ),
                  )
                : RefreshIndicator(
                    color: ColorSchema.primaryColor,
                    onRefresh: notifier.refresh,
                    child: state.pendingCommands.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 90),
                              Icon(
                                Icons.task_alt_rounded,
                                size: 62,
                                color: Color(0xFF9CA3AF),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No quedan comandas QR por revisar.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                            itemCount: state.pendingCommands.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, index) => QrCommandReviewCard(
                              command: state.pendingCommands[index],
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
