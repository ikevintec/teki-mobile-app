import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/inventory_transfer.dart';
import 'package:teki_app/src/presentation/screens/inventory_transfer/widgets/direct_inventory_transfer_sheet.dart';
import 'package:teki_app/src/presentation/screens/inventory_transfer/widgets/inventory_transfer_summary_sheet.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/inventory_transfer/inventory_transfer_provider.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';
import 'package:teki_app/src/utils/notifications.dart';

class InventoryTransferMainScreen extends ConsumerStatefulWidget {
  const InventoryTransferMainScreen({super.key});

  @override
  ConsumerState<InventoryTransferMainScreen> createState() =>
      _InventoryTransferMainScreenState();
}

class _InventoryTransferMainScreenState
    extends ConsumerState<InventoryTransferMainScreen> {
  final ScrollController _scrollController = ScrollController();
  late DateTime _fromDate;
  late DateTime _toDate;
  late final TextEditingController _fromDateController;
  late final TextEditingController _toDateController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = DateTime(now.year, now.month + 1, 0);
    _fromDateController = TextEditingController();
    _toDateController = TextEditingController();
    _syncDateControllers();
    _scrollController.addListener(_onScroll);
    Future.microtask(_refresh);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final officeId = ref.read(sesionProvider).office?.id;
    if (officeId == null) {
      warningNotification(
        'Selecciona un punto de venta para ver los traslados',
      );
      return;
    }
    await _refreshForOffice(officeId);
  }

  Future<void> _refreshForOffice(int officeId) async {
    await ref
        .read(inventoryTransferProvider.notifier)
        .refresh(officeId, desde: _fromDate, hasta: _toDate);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 250) {
      ref.read(inventoryTransferProvider.notifier).loadNextPage();
    }
  }

  Future<void> _openDirectTransfer() async {
    final completed = await DirectInventoryTransferSheet.show(context);
    if (completed && mounted) await _refresh();
  }

  void _syncDateControllers() {
    final format = DateFormat('dd/MM/yyyy');
    _fromDateController.text = format.format(_fromDate);
    _toDateController.text = format.format(_toDate);
  }

  Future<void> _selectFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      helpText: 'Seleccionar fecha desde',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked == null || !mounted || _isSameDay(picked, _fromDate)) return;

    setState(() {
      _fromDate = _dateOnly(picked);
      if (_toDate.isBefore(_fromDate)) {
        _toDate = _fromDate;
      }
      _syncDateControllers();
    });
    await _refresh();
  }

  Future<void> _selectToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate.isBefore(_fromDate) ? _fromDate : _toDate,
      firstDate: _fromDate,
      lastDate: DateTime(2100, 12, 31),
      helpText: 'Seleccionar fecha hasta',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked == null || !mounted || _isSameDay(picked, _toDate)) return;

    final normalized = _dateOnly(picked);
    if (normalized.isBefore(_fromDate)) {
      warningNotification(
        'La fecha hasta debe ser mayor o igual que la fecha desde',
      );
      return;
    }
    setState(() {
      _toDate = normalized;
      _syncDateControllers();
    });
    await _refresh();
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool _isSameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryTransferProvider);

    ref.listen(sesionProvider, (previous, next) {
      if (previous?.office?.id != next.office?.id && next.office?.id != null) {
        _refreshForOffice(next.office!.id!);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: CustomAppBar(
          navigateName: 'Traslados',
          onSettingsReturn: _refresh,
        ),
      ),
      body: Column(
        children: [
          _buildDateFilters(),
          Expanded(
            child: RefreshIndicator(
              color: ColorSchema.primaryColor,
              onRefresh: _refresh,
              child: _buildBody(state),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openDirectTransfer,
        backgroundColor: ColorSchema.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.swap_horiz_rounded),
        label: const Text(
          'Traslado r\u00e1pido',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildDateFilters() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _DateFilterInput(
              label: 'Desde',
              controller: _fromDateController,
              onTap: _selectFromDate,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _DateFilterInput(
              label: 'Hasta',
              controller: _toDateController,
              onTap: _selectToDate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(InventoryTransferState state) {
    if (state.isLoading && state.items.isEmpty) {
      return ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 150),
          Center(
            child: Column(
              children: [
                CircularProgressIndicator(
                  color: ColorSchema.primaryColor,
                  strokeWidth: 2,
                ),
                SizedBox(height: 12),
                Text('Cargando traslados...'),
              ],
            ),
          ),
        ],
      );
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        children: [
          const SizedBox(height: 130),
          Icon(Icons.cloud_off_rounded, size: 52, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            state.errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ),
        ],
      );
    }

    if (state.items.isEmpty) {
      return ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        children: [
          const SizedBox(height: 130),
          Icon(
            Icons.swap_horiz_rounded,
            size: 64,
            color: ColorSchema.primaryColor.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 12),
          Text(
            'A\u00fan no hay traslados',
            textAlign: TextAlign.center,
            style: GoogleFonts.raleway(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF34364A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Desliza hacia abajo para actualizar o crea un traslado r\u00e1pido.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      itemCount: state.items.length + 1,
      itemBuilder: (context, index) {
        if (index == state.items.length) {
          if (state.isLoading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: CircularProgressIndicator(
                  color: ColorSchema.primaryColor,
                  strokeWidth: 2,
                ),
              ),
            );
          }
          if (state.last) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'No hay m\u00e1s traslados',
                  style: TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ),
            );
          }
          return const SizedBox(height: 32);
        }
        final transfer = state.items[index];
        return _InventoryTransferCard(
          transfer: transfer,
          onTap: () => InventoryTransferSummarySheet.show(context, transfer),
        );
      },
    );
  }
}

class _DateFilterInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onTap;

  const _DateFilterInput({
    required this.label,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          tooltip: 'Seleccionar $label',
          onPressed: onTap,
          icon: const Icon(
            Icons.calendar_month_outlined,
            size: 20,
            color: ColorSchema.primaryColor,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FC),
        isDense: true,
        contentPadding: const EdgeInsets.fromLTRB(12, 13, 4, 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: ColorSchema.primaryColor,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _InventoryTransferCard extends StatelessWidget {
  final InventoryTransfer transfer;
  final VoidCallback onTap;

  const _InventoryTransferCard({required this.transfer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final stateColor = _statusColor(transfer.estadoTraslado);
    final date = transfer.fechaSolicitud;
    final source = transfer.puntoVentaOrigen?.nombre ?? 'Sin origen';
    final destination = transfer.puntoVentaDestino?.nombre ?? 'Sin destino';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Traslado #${transfer.id ?? '-'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF27293D),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: stateColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        normalizeEnumLabel(transfer.estadoTraslado),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: stateColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: _OfficeLabel(title: 'Origen', value: source),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 19,
                        color: ColorSchema.primaryColor.withValues(alpha: 0.65),
                      ),
                    ),
                    Expanded(
                      child: _OfficeLabel(
                        title: 'Destino',
                        value: destination,
                        alignEnd: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Divider(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 7,
                  children: [
                    _InfoLabel(
                      icon: Icons.inventory_2_outlined,
                      text:
                          '${transfer.items.length} producto${transfer.items.length == 1 ? '' : 's'}',
                    ),
                    _InfoLabel(
                      icon: Icons.numbers_rounded,
                      text:
                          'Cantidad: ${formatDouble(transfer.cantidadSolicitadaTotal)}',
                    ),
                    if (date != null)
                      _InfoLabel(
                        icon: Icons.schedule_rounded,
                        text: DateFormat(
                          'dd/MM/yyyy HH:mm',
                        ).format(date.toLocal()),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'RECEPCIONADO':
        return const Color(0xFF26845B);
      case 'ATENDIDO':
        return const Color(0xFF2768B2);
      case 'ANULADO':
        return const Color(0xFFC33B43);
      case 'SOLICITADO':
      default:
        return const Color(0xFFB7791F);
    }
  }
}

class _OfficeLabel extends StatelessWidget {
  final String title;
  final String value;
  final bool alignEnd;

  const _OfficeLabel({
    required this.title,
    required this.value,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 10, color: Colors.black45),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF34364A),
          ),
        ),
      ],
    );
  }
}

class _InfoLabel extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}
