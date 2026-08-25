import 'package:flutter/material.dart';
import 'package:teki_app/src/data/models/teki_model/batch_product.dart';
import 'package:teki_app/src/utils/constants.dart';

class DirectTransferSeriesSheet extends StatefulWidget {
  final String productName;
  final int requiredCount;
  final List<BatchProduct> availableSeries;
  final List<BatchProduct> selectedSeries;

  const DirectTransferSeriesSheet({
    super.key,
    required this.productName,
    required this.requiredCount,
    required this.availableSeries,
    required this.selectedSeries,
  });

  static Future<List<BatchProduct>?> show(
    BuildContext context, {
    required String productName,
    required int requiredCount,
    required List<BatchProduct> availableSeries,
    required List<BatchProduct> selectedSeries,
  }) {
    FocusManager.instance.primaryFocus?.unfocus();
    return showModalBottomSheet<List<BatchProduct>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DirectTransferSeriesSheet(
        productName: productName,
        requiredCount: requiredCount,
        availableSeries: availableSeries,
        selectedSeries: selectedSeries,
      ),
    );
  }

  @override
  State<DirectTransferSeriesSheet> createState() =>
      _DirectTransferSeriesSheetState();
}

class _DirectTransferSeriesSheetState extends State<DirectTransferSeriesSheet> {
  late final List<BatchProduct> _availableSeries;
  late List<BatchProduct> _selectedSeries;

  @override
  void initState() {
    super.initState();
    _availableSeries = [...widget.availableSeries]
      ..sort(
        (first, second) => (first.serie ?? '').compareTo(second.serie ?? ''),
      );
    final availableIds = _availableSeries.map((serie) => serie.id).toSet();
    _selectedSeries = widget.selectedSeries
        .where((serie) => availableIds.contains(serie.id))
        .toList();
  }

  bool get _hasEnoughSeries => _availableSeries.length >= widget.requiredCount;

  bool get _isValid =>
      _hasEnoughSeries && _selectedSeries.length == widget.requiredCount;

  void _toggleSeries(BatchProduct series) {
    setState(() {
      final isSelected = _selectedSeries.any((item) => item.id == series.id);
      if (isSelected) {
        _selectedSeries.removeWhere((item) => item.id == series.id);
      } else if (_selectedSeries.length < widget.requiredCount) {
        _selectedSeries.add(series);
      }
    });
  }

  void _confirm() {
    if (!_isValid) return;
    Navigator.of(context).pop(List<BatchProduct>.from(_selectedSeries));
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          Flexible(
            child: _availableSeries.isEmpty
                ? _buildEmptyState()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    shrinkWrap: true,
                    children: [
                      _buildSelectionSummary(),
                      const SizedBox(height: 10),
                      ..._availableSeries.map(_buildSeriesOption),
                    ],
                  ),
          ),
          _buildConfirmArea(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 8, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: ColorSchema.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: ColorSchema.primaryColor,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seleccionar series',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF27293D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedSeries.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _selectedSeries = []),
                  child: const Text('Limpiar'),
                ),
              IconButton(
                tooltip: 'Cerrar',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionSummary() {
    final color = _isValid
        ? const Color(0xFF26734D)
        : _hasEnoughSeries
        ? const Color(0xFF9A6700)
        : Colors.red.shade700;
    final background = _isValid
        ? const Color(0xFFE8F5EE)
        : _hasEnoughSeries
        ? const Color(0xFFFFF7DF)
        : const Color(0xFFFFEBEE);
    final message = !_hasEnoughSeries
        ? 'Series insuficientes: hay ${_availableSeries.length} disponibles y se requieren ${widget.requiredCount}.'
        : 'Seleccionadas ${_selectedSeries.length} de ${widget.requiredCount} series requeridas.';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Icon(
            _isValid
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
            size: 19,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(fontSize: 12, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildSeriesOption(BatchProduct series) {
    final isSelected = _selectedSeries.any((item) => item.id == series.id);
    final reachedLimit =
        !isSelected && _selectedSeries.length >= widget.requiredCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? ColorSchema.primaryColor : Colors.grey.shade200,
        ),
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: reachedLimit ? null : (_) => _toggleSeries(series),
        activeColor: ColorSchema.primaryColor,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        dense: true,
        title: Text(
          series.serie?.trim().isNotEmpty == true
              ? series.serie!.trim()
              : 'Serie #${series.id ?? '-'}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        subtitle: const Text(
          'Disponible en el punto de venta origen',
          style: TextStyle(fontSize: 10),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_2_rounded, size: 48, color: Colors.black26),
          SizedBox(height: 10),
          Text(
            'No hay series disponibles en el punto de venta origen.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: FilledButton.icon(
          onPressed: _isValid ? _confirm : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: ColorSchema.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.check_rounded),
          label: Text(
            'Confirmar ${widget.requiredCount} serie${widget.requiredCount == 1 ? '' : 's'}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
