import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/presentation/screens/restaurant/widgets/qr_command_review/qr_command_review_sheet.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/restaurant/qr_command_review_provider.dart';
import 'package:teki_app/src/providers/restaurant/restaurant_provider.dart';
import 'package:teki_app/src/utils/constants.dart';

class QrCommandReviewArea extends ConsumerStatefulWidget {
  const QrCommandReviewArea({super.key});

  @override
  ConsumerState<QrCommandReviewArea> createState() =>
      _QrCommandReviewAreaState();
}

class _QrCommandReviewAreaState extends ConsumerState<QrCommandReviewArea> {
  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) _initialize(ref.read(sesionProvider));
    });
  }

  Future<void> _initialize(SesionState session) async {
    final office = session.office;
    if (office?.id == null) return;
    await ref
        .read(qrCommandReviewProvider.notifier)
        .initialize(
          office: office!,
          config: session.config,
          companyId: session.companySelected?.id ?? session.company?.id,
        );
  }

  void _reloadTables() {
    final officeId = ref.read(sesionProvider).office?.id;
    if (officeId != null) {
      ref.read(restaurantProvider.notifier).reload(officeId);
    }
  }

  Future<void> _openSheet() async {
    if (_sheetOpen || !mounted) return;
    setState(() => _sheetOpen = true);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const QrCommandReviewSheet(),
    );
    if (mounted) setState(() => _sheetOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SesionState>(sesionProvider, (previous, next) {
      if (previous?.office?.id != next.office?.id ||
          previous?.config != next.config ||
          previous?.companySelected?.id != next.companySelected?.id) {
        _initialize(next);
      }
    });
    ref.listen<int>(
      qrCommandReviewProvider.select((state) => state.autoOpenRequest),
      (previous, next) {
        if (next > (previous ?? 0)) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _openSheet());
        }
      },
    );
    ref.listen<int>(
      qrCommandReviewProvider.select((state) => state.tablesRefreshRequest),
      (previous, next) {
        if (next > (previous ?? 0)) _reloadTables();
      },
    );

    final total = ref.watch(
      qrCommandReviewProvider.select((state) => state.pendingCommands.length),
    );
    if (total == 0 || _sheetOpen) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      heroTag: 'qr-command-review',
      onPressed: _openSheet,
      backgroundColor: const Color(0xFFF59E0B),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.qr_code_scanner_rounded),
      label: Text(
        total == 1 ? '1 QR por aprobar' : '$total QR por aprobar',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: ColorSchema.primaryColor.withValues(alpha: 0.18),
        ),
      ),
    );
  }
}
