import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/batch_product.dart';
import 'package:teki_app/src/data/models/teki_model/batch_product_sale.dart';
import 'package:teki_app/src/data/models/teki_model/ticket_detail.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/utils/constants.dart';

Future<void> showSeriesConfigSheet(
  BuildContext context, {
  required TicketDetail ticketDetail,
  required int index,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SeriesConfigSheet(ticketDetail: ticketDetail, index: index),
  ).then((_) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => FocusManager.instance.primaryFocus?.unfocus(),
    );
  });
}

class SeriesConfigSheet extends ConsumerStatefulWidget {
  final TicketDetail ticketDetail;
  final int index;

  const SeriesConfigSheet({
    super.key,
    required this.ticketDetail,
    required this.index,
  });

  @override
  ConsumerState<SeriesConfigSheet> createState() => _SeriesConfigSheetState();
}

class _SeriesConfigSheetState extends ConsumerState<SeriesConfigSheet> {
  List<BatchProduct> _availableSeries = [];
  List<BatchProduct> _selectedSeries = [];

  @override
  void initState() {
    super.initState();
    _loadSeries();
  }

  int get _quantity => (widget.ticketDetail.cantidad ?? 1).toInt();

  void _loadSeries() {
    final product = widget.ticketDetail.producto;
    if (product == null) return;

    final officeId = ref.read(sesionProvider).office?.id;

    final matchingInventories = (product.inventarios ?? [])
        .where((inv) => inv.puntoVenta?.id == officeId);

    final series = <BatchProduct>[];
    for (final inv in matchingInventories) {
      for (final lote in (inv.lotes ?? [])) {
        if (lote.tipoLote == 'SERIE' && (lote.cantidad ?? 0) == 1) {
          series.add(lote);
        }
      }
    }

    _availableSeries = series;

    final existingLotes = widget.ticketDetail.lotes ?? [];
    if (existingLotes.length == _quantity) {
      final existingIds = existingLotes.map((l) => l.lote?.id).toSet();
      final restored =
          series.where((s) => existingIds.contains(s.id)).toList();
      if (restored.length == _quantity) {
        _selectedSeries = restored;
        return;
      }
    }

    _selectedSeries = series.take(_quantity).toList();
  }

  bool get _isInsufficient => _availableSeries.length < _quantity;
  bool get _isValid => _selectedSeries.length == _quantity && !_isInsufficient;

  void _toggleSerie(BatchProduct serie) {
    setState(() {
      final alreadySelected = _selectedSeries.any((s) => s.id == serie.id);
      if (alreadySelected) {
        _selectedSeries.removeWhere((s) => s.id == serie.id);
      } else if (_selectedSeries.length < _quantity) {
        _selectedSeries.add(serie);
      }
    });
  }

  void _confirm() {
    if (!_isValid) return;

    final lotes = _selectedSeries
        .map((s) => BatchProductSale(lote: s, cantidad: 1))
        .toList();

    ref
        .read(productSaleProvider.notifier)
        .updateLotesProductSale(widget.index, lotes);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Configurar Series',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close,
                      size: 22, color: Colors.black54),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Scrollable content
          Flexible(
            child: _availableSeries.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No hay series disponibles en este punto de venta.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    shrinkWrap: true,
                    children: [
                      if (_isInsufficient)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Colors.red.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Series insuficientes. '
                                  'Disponibles: ${_availableSeries.length}, requeridas: $_quantity.',
                                  style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Selecciona $_quantity serie${_quantity != 1 ? 's' : ''} '
                          '(${_selectedSeries.length}/$_quantity seleccionadas)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _isValid
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      ),
                      ..._availableSeries.map((serie) {
                        final isSelected =
                            _selectedSeries.any((s) => s.id == serie.id);
                        final atLimit = !isSelected &&
                            _selectedSeries.length >= _quantity;
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (_isInsufficient || atLimit)
                              ? null
                              : (_) => _toggleSerie(serie),
                          title: Text(
                            serie.serie ?? 'Serie #${serie.id}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          activeColor: ColorSchema.primaryColor,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        );
                      }),
                    ],
                  ),
          ),
          // Fixed confirm button
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isValid ? _confirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorSchema.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Confirmar series',
                    style: TextStyle(fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
