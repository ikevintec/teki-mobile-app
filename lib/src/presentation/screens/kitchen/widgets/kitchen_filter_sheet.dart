import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/teki_model/production_area.dart';
import 'package:teki_app/src/providers/kitchen/kitchen_state.dart';
import 'package:teki_app/src/utils/constants.dart';

class KitchenFilterSheet extends StatefulWidget {
  final KitchenFilters filters;
  final List<ProductionArea> productionAreas;
  final ValueChanged<KitchenFilters> onApply;

  const KitchenFilterSheet({
    super.key,
    required this.filters,
    required this.productionAreas,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required KitchenFilters filters,
    required List<ProductionArea> productionAreas,
    required ValueChanged<KitchenFilters> onApply,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => KitchenFilterSheet(
        filters: filters,
        productionAreas: productionAreas,
        onApply: onApply,
      ),
    );
  }

  @override
  State<KitchenFilterSheet> createState() => _KitchenFilterSheetState();
}

class _KitchenFilterSheetState extends State<KitchenFilterSheet> {
  late Set<int> _selectedAreas;
  late int _preparationMinutes;
  late bool _soundEnabled;
  late KitchenAlertTone _alertTone;
  late bool _lateAlertEnabled;
  late bool _showCancelled;

  @override
  void initState() {
    super.initState();
    _selectedAreas = widget.filters.productionAreaIds.toSet();
    _preparationMinutes = widget.filters.preparationMinutes;
    _soundEnabled = widget.filters.soundEnabled;
    _alertTone = widget.filters.alertTone;
    _lateAlertEnabled = widget.filters.lateAlertEnabled;
    _showCancelled = widget.filters.showCancelled;
  }

  void _apply() {
    widget.onApply(
      widget.filters.copyWith(
        productionAreaIds: _selectedAreas.toList()..sort(),
        preparationMinutes: _preparationMinutes,
        soundEnabled: _soundEnabled,
        alertTone: _alertTone,
        lateAlertEnabled: _lateAlertEnabled,
        showCancelled: _showCancelled,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 12, 18, 18 + bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.tune_rounded, color: ColorSchema.primaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Filtros y ajustes de cocina',
                    style: GoogleFonts.raleway(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (_selectedAreas.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(_selectedAreas.clear),
                    child: Text('Limpiar zonas (${_selectedAreas.length})'),
                  ),
              ],
            ),
            const Divider(height: 22),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Zonas de producción'),
                    if (widget.productionAreas.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'No hay zonas configuradas.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          for (final area in widget.productionAreas)
                            FilterChip(
                              label: Text(area.nombre ?? 'Zona ${area.id}'),
                              selected:
                                  area.id != null &&
                                  _selectedAreas.contains(area.id),
                              onSelected: area.id == null
                                  ? null
                                  : (selected) => setState(() {
                                      if (selected) {
                                        _selectedAreas.add(area.id!);
                                      } else {
                                        _selectedAreas.remove(area.id);
                                      }
                                    }),
                              selectedColor: ColorSchema.primaryColor
                                  .withValues(alpha: 0.14),
                              checkmarkColor: ColorSchema.primaryColor,
                            ),
                        ],
                      ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(child: _sectionTitle('Alerta de tiempo')),
                        Text(
                          '$_preparationMinutes min',
                          style: const TextStyle(
                            color: ColorSchema.primaryColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        valueIndicatorColor: ColorSchema.primaryColor,
                      ),
                      child: Slider(
                        value: _preparationMinutes.toDouble(),
                        min: 5,
                        max: 60,
                        divisions: 11,
                        label: '$_preparationMinutes min',
                        activeColor: ColorSchema.primaryColor,
                        inactiveColor: ColorSchema.primaryColor.withValues(
                          alpha: 0.18,
                        ),
                        onChanged: (value) =>
                            setState(() => _preparationMinutes = value.round()),
                      ),
                    ),
                    Text(
                      'La tarjeta se vuelve ámbar a los $_preparationMinutes min '
                      'y roja a los ${_preparationMinutes * 2} min.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SettingsSwitch(
                      icon: _soundEnabled
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      title: 'Avisos de sonido y vibración',
                      subtitle: 'Comandas nuevas y anulaciones importantes',
                      value: _soundEnabled,
                      onChanged: (value) =>
                          setState(() => _soundEnabled = value),
                    ),
                    if (_soundEnabled) ...[
                      const SizedBox(height: 4),
                      _sectionTitle('Tono de comanda nueva'),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<KitchenAlertTone>(
                          segments: [
                            for (final tone in KitchenAlertTone.values)
                              ButtonSegment(
                                value: tone,
                                label: Text(tone.label),
                              ),
                          ],
                          selected: {_alertTone},
                          showSelectedIcon: false,
                          style: SegmentedButton.styleFrom(
                            foregroundColor: ColorSchema.primaryColor,
                            selectedForegroundColor: Colors.white,
                            selectedBackgroundColor: ColorSchema.primaryColor,
                          ),
                          onSelectionChanged: (selection) =>
                              setState(() => _alertTone = selection.first),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    _SettingsSwitch(
                      icon: Icons.notification_important_outlined,
                      title: 'Avisar cuando una comanda pase a rojo',
                      value: _lateAlertEnabled,
                      onChanged: (value) =>
                          setState(() => _lateAlertEnabled = value),
                    ),
                    _SettingsSwitch(
                      icon: Icons.block_rounded,
                      title: 'Mostrar platos anulados en cada comanda',
                      value: _showCancelled,
                      onChanged: (value) =>
                          setState(() => _showCancelled = value),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _apply,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Aplicar'),
                style: FilledButton.styleFrom(
                  backgroundColor: ColorSchema.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitch({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      activeThumbColor: Colors.white,
      activeTrackColor: ColorSchema.primaryColor,
      secondary: Icon(icon, color: ColorSchema.primaryColor, size: 21),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: const TextStyle(fontSize: 11)),
      value: value,
      onChanged: onChanged,
    );
  }
}
