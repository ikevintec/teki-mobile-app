import 'dart:async';
import 'package:flutter/material.dart';
import 'pedidos_ui.dart';

/// Hoja de búsqueda del pedido.
/// - Sin [agregar]: selección simple, devuelve el elemento elegido.
/// - Con [agregar]: la hoja queda abierta para sumar varios productos seguidos;
///   [enPedido] indica cuánto lleva ya el pedido de cada resultado.
/// - [lateral]: dato principal y secundario a la derecha (p. ej. precio y stock).
/// - [etiqueta]: texto destacado aparte (p. ej. la promoción vigente).
Future<T?> buscarEnPedido<T>(
  BuildContext context,
  String titulo,
  Future<List<T>> Function(String) buscar,
  String Function(T) texto, {
  String? Function(T)? subtitulo,
  (String, String?) Function(T)? lateral,
  String? Function(T)? etiqueta,
  Future<void> Function(T)? agregar,
  double Function(T)? enPedido,
  String vacio = 'Escribe un nombre o código para buscar.',
  Widget? accionExtra,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  // En modo múltiple, arrastrar la hoja la cierra con Navigator.pop directo
  // (ignora PopScope) y dejaría productos a medio agregar: se cierra solo con
  // el botón, el toque fuera o atrás, que sí respetan el bloqueo.
  enableDrag: agregar == null,
  builder: (_) => _BusquedaPedido<T>(
    titulo: titulo,
    buscar: buscar,
    texto: texto,
    subtitulo: subtitulo,
    lateral: lateral,
    etiqueta: etiqueta,
    agregar: agregar,
    enPedido: enPedido,
    vacio: vacio,
    accionExtra: accionExtra,
  ),
);

String cantidadPedido(double? n) {
  final v = n ?? 0;
  return v % 1 == 0 ? v.toInt().toString() : v.toString();
}

class _BusquedaPedido<T> extends StatefulWidget {
  final String titulo, vacio;
  final Future<List<T>> Function(String) buscar;
  final String Function(T) texto;
  final String? Function(T)? subtitulo;
  final (String, String?) Function(T)? lateral;
  final String? Function(T)? etiqueta;
  final Future<void> Function(T)? agregar;
  final double Function(T)? enPedido;
  final Widget? accionExtra;
  const _BusquedaPedido({
    required this.titulo,
    required this.buscar,
    required this.texto,
    required this.vacio,
    this.subtitulo,
    this.lateral,
    this.etiqueta,
    this.agregar,
    this.enPedido,
    this.accionExtra,
  });
  @override
  State<_BusquedaPedido<T>> createState() => _BusquedaPedidoState<T>();
}

class _BusquedaPedidoState<T> extends State<_BusquedaPedido<T>> {
  final _texto = TextEditingController();
  Timer? _timer;
  int _version = 0, _agregados = 0, _pendientes = 0;
  bool _cargando = false;
  Future<void> _cola = Future.value();
  String? _error;
  List<T> _items = [];
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _buscar(''));
  }

  Future<void> _buscar(String q) async {
    final v = ++_version;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final items = await widget.buscar(q);
      if (mounted && v == _version) setState(() => _items = items);
    } catch (e) {
      if (mounted && v == _version) setState(() => _error = mensajePedido(e));
    } finally {
      if (mounted && v == _version) setState(() => _cargando = false);
    }
  }

  Future<void> _tocar(T item) async {
    if (widget.agregar == null) {
      Navigator.pop(context, item);
      return;
    }
    // Los toques rápidos se encolan para no perder ninguno.
    setState(() => _pendientes++);
    _cola = _cola.then((_) async {
      try {
        await widget.agregar!(item);
        if (mounted) setState(() => _agregados++);
      } catch (e) {
        if (mounted) setState(() => _error = mensajePedido(e));
      } finally {
        if (mounted) setState(() => _pendientes--);
      }
    });
    await _cola;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multiple = widget.agregar != null;
    // Toque fuera de la hoja o gesto atrás: no cerrar con productos en camino.
    return PopScope(
      canPop: _pendientes == 0,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .8,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _texto,
                  autofocus: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: widget.titulo,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (q) {
                    _timer?.cancel();
                    _version++;
                    _timer = Timer(
                      const Duration(milliseconds: 250),
                      () => _buscar(q),
                    );
                  },
                ),
              ),
              if (widget.accionExtra != null) widget.accionExtra!,
              if (_cargando || _pendientes > 0) const LinearProgressIndicator(),
              if (_error != null)
                ListTile(
                  title: Text(_error!),
                  trailing: TextButton(
                    onPressed: () => _buscar(_texto.text),
                    child: const Text('Reintentar'),
                  ),
                ),
              Expanded(
                child: !_cargando && _error == null && _items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _texto.text.trim().isEmpty
                                ? widget.vacio
                                : 'Sin resultados. Prueba otro nombre o código.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) {
                          final item = _items[i];
                          final sub = widget.subtitulo?.call(item);
                          final llevo = widget.enPedido?.call(item) ?? 0;
                          final lado = widget.lateral?.call(item);
                          final promo = widget.etiqueta?.call(item);
                          final tema = Theme.of(context);
                          return ListTile(
                            title: Text(widget.texto(item)),
                            subtitle:
                                (sub == null || sub.isEmpty) && promo == null
                                ? null
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (sub != null && sub.isNotEmpty)
                                        Text(
                                          sub,
                                          style: tema.textTheme.bodySmall
                                              ?.copyWith(
                                                color: tema
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      if (promo != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: tema
                                                  .colorScheme
                                                  .tertiaryContainer,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '🎁 $promo',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: tema.textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: tema
                                                        .colorScheme
                                                        .onTertiaryContainer,
                                                  ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                            trailing: !multiple && lado == null
                                ? null
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (lado != null) ...[
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              lado.$1,
                                              style: tema.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            if (lado.$2 != null)
                                              Text(
                                                lado.$2!,
                                                style: tema.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: tema
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                      if (multiple) ...[
                                        if (llevo > 0) ...[
                                          Icon(
                                            Icons.check_circle,
                                            size: 18,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            cantidadPedido(llevo),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                        ],
                                        const Icon(Icons.add_circle_outline),
                                      ],
                                    ],
                                  ),
                            onTap: () => _tocar(item),
                          );
                        },
                      ),
              ),
              if (multiple)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        // No se cierra con productos aún en camino al pedido.
                        onPressed: _pendientes > 0
                            ? null
                            : () => Navigator.pop(context),
                        child: Text(
                          _pendientes > 0
                              ? 'Agregando…'
                              : _agregados == 0
                              ? 'Cerrar'
                              : 'Listo ($_agregados)',
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
