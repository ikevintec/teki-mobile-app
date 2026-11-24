import 'pedido_list_item.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/domain/distribuidor/filtros_pedidos.dart';
import 'pedidos_style.dart';
import 'filtros_pedidos_sheet.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/distribuidor/bonificaciones_provider.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_provider.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';

import 'pedido_form.dart';
import 'detalle_pedido.dart';
import 'pedidos_ui.dart';

class PedidosScreen extends StatelessWidget {
  const PedidosScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const PedidosStyle(child: _PedidosContent());
}

class _PedidosContent extends ConsumerStatefulWidget {
  const _PedidosContent();
  @override
  ConsumerState<_PedidosContent> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends ConsumerState<_PedidosContent> {
  List<Map<String, dynamic>> _pedidos = [], _borradores = [];
  bool _cargando = true, _mas = true, _masBorradores = false;
  int _pagina = 0, _paginaBorrador = 0;
  int _carga = 0;
  String? _error;
  FiltrosPedidos _filtros = const FiltrosPedidos();
  final _busqueda = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    ++_carga;
    _debounce?.cancel();
    _busqueda.dispose();
    super.dispose();
  }

  void _buscar(String texto) {
    _debounce?.cancel();
    ++_carga;
    setState(() {
      _filtros = _filtros.conCliente(texto);
      _pedidos = [];
      _mas = false;
      _cargando = true;
    });
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _cargar(recargarBorradores: false),
    );
  }

  Future<void> _filtrar() async {
    final clave = ref.read(sesionProvider).claveContexto;
    final filtros = await showModalBottomSheet<FiltrosPedidos>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => FiltrosPedidosSheet(filtros: _filtros),
    );
    if (!mounted ||
        filtros == null ||
        ref.read(sesionProvider).claveContexto != clave) {
      return;
    }
    _debounce?.cancel();
    _busqueda.text = filtros.cliente;
    setState(() => _filtros = filtros);
    await _cargar(recargarBorradores: false);
  }

  void _limpiar() {
    _debounce?.cancel();
    _busqueda.clear();
    setState(() => _filtros = const FiltrosPedidos());
    _cargar(recargarBorradores: false);
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_cargar);
  }

  Future<void> _cargar({
    bool mas = false,
    bool recargarBorradores = true,
  }) async {
    _debounce?.cancel();
    final carga = ++_carga;
    setState(() {
      _cargando = true;
      _error = null;
      if (!mas) {
        _pedidos = [];
        _mas = false;
      }
    });
    try {
      final s = ref.read(sesionProvider);
      final clave = s.claveContexto;
      final api = servicioPedidos(s);
      final pagina = mas ? _pagina + 1 : 0;
      final pedidos = await api.listar(
        s.office!.id!,
        s.login.user!.id!,
        pagina: pagina,
        filtros: _filtros,
      );
      final borradores = mas || !recargarBorradores
          ? _borradores
          : await api.borradores(sede: s.office!.id!);
      if (!mounted ||
          carga != _carga ||
          ref.read(sesionProvider).claveContexto != clave) {
        return;
      }
      setState(() {
        _pedidos = mas ? [..._pedidos, ...pedidos] : pedidos;
        _borradores = borradores;
        if (!mas && recargarBorradores) {
          _paginaBorrador = 0;
          _masBorradores = borradores.length == 20;
        }
        _pagina = pagina;
        _mas = pedidos.length == 20;
      });
    } catch (e) {
      if (mounted && carga == _carga) setState(() => _error = mensajePedido(e));
    } finally {
      if (mounted && carga == _carga) setState(() => _cargando = false);
    }
  }

  Future<void> _cargarMasBorradores() async {
    final carga = ++_carga;
    setState(() => _cargando = true);
    final s = ref.read(sesionProvider);
    final clave = s.claveContexto;
    try {
      final pagina = _paginaBorrador + 1;
      final nuevos = await servicioPedidos(
        s,
      ).borradores(sede: s.office!.id!, pagina: pagina);
      if (!mounted ||
          carga != _carga ||
          ref.read(sesionProvider).claveContexto != clave) {
        return;
      }
      setState(() {
        _borradores = [..._borradores, ...nuevos];
        _paginaBorrador = pagina;
        _masBorradores = nuevos.length == 20;
      });
    } catch (e) {
      if (mounted && carga == _carga) setState(() => _error = mensajePedido(e));
    } finally {
      if (mounted && carga == _carga) setState(() => _cargando = false);
    }
  }

  Future<void> _abrir({
    Map<String, dynamic>? pedido,
    Map<String, dynamic>? borrador,
  }) async {
    final resultado = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => ProviderScope(
          overrides: [
            bonificacionesProvider.overrideWith(crearBonificaciones),
            ticketProvider.overrideWith(crearTicketVenta),
            productSaleProvider.overrideWith(crearCarritoVenta),
            customerSaleProvider.overrideWith(crearClienteVenta),
          ],
          child: PedidosStyle(
            child: PedidoForm(pedido: pedido, borrador: borrador),
          ),
        ),
      ),
    );
    if (!mounted) return;
    // "Nuevo pedido" desde la pantalla de éxito: siguiente bodega sin pasar por la lista.
    if (resultado == 'nuevo') {
      unawaited(_cargar());
      await _abrir();
      return;
    }
    await _cargar();
  }

  Future<void> _detalle(Map<String, dynamic> item) async {
    final clave = ref.read(sesionProvider).claveContexto;
    try {
      final pedido = await servicioPedidos(
        ref.read(sesionProvider),
      ).obtener((item['id'] as num).toInt());
      if (!mounted || ref.read(sesionProvider).claveContexto != clave) return;
      if (pedido['puedeEditarPedido'] == true) {
        await _abrir(pedido: pedido);
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        showDragHandle: false,
        builder: (_) => DetallePedido(pedido: pedido),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mensajePedido(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(sesionProvider.select((s) => s.claveContexto), (_, _) {
      ++_carga;
      _debounce?.cancel();
      _busqueda.clear();
      setState(() {
        _filtros = const FiltrosPedidos();
        _pedidos = [];
        _borradores = [];
        _masBorradores = false;
        _error = null;
      });
      Future.microtask(() {
        if (mounted) _cargar();
      });
    });
    final s = ref.watch(sesionProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis pedidos'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargando ? null : _cargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrir(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo pedido'),
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            Text(
              s.office?.nombre ?? '',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _busqueda,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Cliente o documento',
                hintText: 'Nombre, DNI o RUC',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busqueda.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar búsqueda',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _busqueda.clear();
                          _buscar('');
                        },
                      ),
              ),
              onChanged: _buscar,
              onSubmitted: (_) {
                _debounce?.cancel();
                _cargar(recargarBorradores: false);
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Tooltip(
                message: 'Filtros de pedidos',
                child: TextButton.icon(
                  onPressed: _filtrar,
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  icon: const Icon(Icons.filter_list_outlined),
                  label: Text(
                    _filtros.cantidad == 0
                        ? 'Más filtros'
                        : 'Más filtros (${_filtros.cantidad})',
                  ),
                ),
              ),
            ),
            if (_filtros.cantidad > 0)
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (_filtros.estado != null)
                    Chip(
                      label: Text(
                        estadosFiltroPedido[_filtros.estado] ??
                            _filtros.estado!,
                      ),
                    ),
                  if (_filtros.desde != null)
                    Chip(
                      label: Text(
                        '${DateFormat('dd/MM/yyyy').format(_filtros.desde!)} – ${DateFormat('dd/MM/yyyy').format(_filtros.hasta!)}',
                      ),
                    ),
                  if (_filtros.serie.isNotEmpty)
                    Chip(label: Text('Serie ${_filtros.serie}')),
                  if (_filtros.numero != null)
                    Chip(label: Text('N.º ${_filtros.numero}')),
                  if (!_filtros.recientesPrimero)
                    const Chip(label: Text('Más antiguos primero')),
                  TextButton(
                    onPressed: _limpiar,
                    child: const Text('Limpiar filtros'),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            if (_cargando) const LinearProgressIndicator(),
            if (_error != null)
              ListTile(
                leading: const Icon(Icons.error_outline),
                title: Text(_error!),
                trailing: TextButton(
                  onPressed: _cargar,
                  child: const Text('Reintentar'),
                ),
              ),
            if (_borradores.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Borradores',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final b in _borradores)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.edit_note),
                    title: Text('${b['nombre'] ?? 'Pedido sin enviar'}'),
                    subtitle: const Text(
                      'Aún no enviado · sin reserva de stock',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _abrir(borrador: b),
                  ),
                ),
            ],
            if (_masBorradores && !_cargando)
              TextButton(
                onPressed: _cargarMasBorradores,
                child: const Text('Ver más borradores'),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Pedidos enviados',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (!_cargando && _error == null && _pedidos.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _filtros.cantidad > 0
                      ? 'No hay pedidos para estos filtros. Prueba otra búsqueda o limpia los filtros.'
                      : 'Aún no tienes pedidos. Crea el primero durante tu visita.',
                ),
              ),
            for (final p in _pedidos)
              PedidoListItem(pedido: p, onTap: () => _detalle(p)),
            if (_mas && !_cargando)
              TextButton(
                onPressed: () => _cargar(mas: true),
                child: const Text('Ver más pedidos'),
              ),
          ],
        ),
      ),
    );
  }
}
