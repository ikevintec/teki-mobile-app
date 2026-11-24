import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/domain/distribuidor/filtros_pedidos.dart';
import 'pedidos_style.dart';

const estadosFiltroPedido = <String, String>{
  'PENDIENTE': 'Pendientes',
  'CONCRETADA': 'Convertidos en venta',
  'ANULADA': 'Anulados',
};

class FiltrosPedidosSheet extends StatefulWidget {
  final FiltrosPedidos filtros;
  const FiltrosPedidosSheet({super.key, required this.filtros});
  @override
  State<FiltrosPedidosSheet> createState() => _FiltrosPedidosSheetState();
}

class _FiltrosPedidosSheetState extends State<FiltrosPedidosSheet> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _cliente, _serie, _numero;
  late String? _estado;
  late DateTime? _desde, _hasta;
  late bool _recientes;

  @override
  void initState() {
    super.initState();
    final f = widget.filtros;
    _cliente = TextEditingController(text: f.cliente);
    _serie = TextEditingController(text: f.serie);
    _numero = TextEditingController(text: f.numero?.toString() ?? '');
    _estado = f.estado;
    _desde = f.desde;
    _hasta = f.hasta;
    _recientes = f.recientesPrimero;
  }

  @override
  void dispose() {
    _cliente.dispose();
    _serie.dispose();
    _numero.dispose();
    super.dispose();
  }

  void _periodo(int? dias) {
    final ahora = DateUtils.dateOnly(DateTime.now());
    setState(() {
      _hasta = dias == null ? null : ahora;
      _desde = dias == null ? null : ahora.subtract(Duration(days: dias - 1));
    });
  }

  Future<void> _fecha(bool inicio) async {
    final valor = await showDatePicker(
      context: context,
      initialDate:
          (inicio ? _desde : _hasta) ?? DateUtils.dateOnly(DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: inicio ? 'Emisión desde' : 'Emisión hasta',
      cancelText: 'Cancelar',
      confirmText: 'Elegir',
    );
    if (!mounted || valor == null) return;
    setState(() {
      if (inicio) {
        _desde = valor;
        _hasta ??= valor;
      } else {
        _hasta = valor;
        _desde ??= valor;
      }
    });
  }

  @override
  Widget build(BuildContext context) => PedidosStyle(
    child: SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Filtrar pedidos',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar filtros',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cliente,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Cliente',
                    hintText: 'Nombre, DNI o RUC',
                    prefixIcon: Icon(Icons.person_search_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _estado ?? '',
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Estado del pedido',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Todos los estados'),
                    ),
                    ...estadosFiltroPedido.entries.map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _estado = v == '' ? null : v),
                ),
                const SizedBox(height: 20),
                const Text('Fecha de emisión'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final p in [
                      (1, 'Hoy'),
                      (7, 'Últimos 7 días'),
                      (30, 'Últimos 30 días'),
                      (null, 'Todas las fechas'),
                    ])
                      ChoiceChip(
                        label: Text(p.$2),
                        selected: p.$1 == null
                            ? _desde == null && _hasta == null
                            : DateUtils.isSameDay(_hasta, DateTime.now()) &&
                                  DateUtils.isSameDay(
                                    _desde,
                                    DateTime.now().subtract(
                                      Duration(days: p.$1! - 1),
                                    ),
                                  ),
                        onSelected: (_) => _periodo(p.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _fecha(true),
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        _desde == null
                            ? 'Desde'
                            : 'Desde ${DateFormat('dd/MM/yyyy').format(_desde!)}',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _fecha(false),
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        _hasta == null
                            ? 'Hasta'
                            : 'Hasta ${DateFormat('dd/MM/yyyy').format(_hasta!)}',
                      ),
                    ),
                  ],
                ),
                if (_desde != null &&
                    _hasta != null &&
                    _desde!.isAfter(_hasta!))
                  Text(
                    'La fecha desde debe ser anterior o igual a la fecha hasta.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _serie,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 20,
                  decoration: const InputDecoration(
                    labelText: 'Serie del pedido',
                    hintText: 'Ej. PE01',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _numero,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Número del pedido',
                    hintText: 'Ej. 123',
                  ),
                  validator: (v) =>
                      v != null &&
                          v.isNotEmpty &&
                          (int.tryParse(v) == null ||
                              int.parse(v) > 2147483647 ||
                              int.parse(v) < 1)
                      ? 'Ingresa un número entre 1 y 2147483647.'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<bool>(
                  initialValue: _recientes,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Ordenar pedidos',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: true,
                      child: Text('Más recientes primero'),
                    ),
                    DropdownMenuItem(
                      value: false,
                      child: Text('Más antiguos primero'),
                    ),
                  ],
                  onChanged: (v) => _recientes = v ?? true,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.search),
                  label: const Text('Aplicar filtros'),
                  onPressed:
                      _desde != null &&
                          _hasta != null &&
                          _desde!.isAfter(_hasta!)
                      ? null
                      : () {
                          if (!_form.currentState!.validate()) return;
                          Navigator.pop(
                            context,
                            FiltrosPedidos(
                              cliente: _cliente.text.trim(),
                              estado: _estado,
                              desde: _desde,
                              hasta: _hasta,
                              serie: _serie.text.trim().toUpperCase(),
                              numero: int.tryParse(_numero.text),
                              recientesPrimero: _recientes,
                            ),
                          );
                        },
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, const FiltrosPedidos()),
                  child: const Text('Limpiar filtros'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
