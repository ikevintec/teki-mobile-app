import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/providers/distribuidor/bonificaciones_provider.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'busqueda_pedido.dart' show cantidadPedido;

/// Misma interacción de beneficios para pedido, venta y cotización; el motor vive en backend.
class BonificacionesPanel extends ConsumerWidget {
  final bool selectorCompacto;
  final Widget? accionesCabecera;

  /// false cuando la pantalla ubica [SelectorTipoPrecio] por su cuenta.
  final bool mostrarSelector;

  /// false cuando la pantalla muestra el cálculo fuera de la lista, para que
  /// la barra no empuje las líneas mientras el usuario toca +/-.
  final bool mostrarCalculando;
  const BonificacionesPanel({
    super.key,
    this.selectorCompacto = false,
    this.accionesCabecera,
    this.mostrarSelector = true,
    this.mostrarCalculando = true,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(bonificacionesProvider);
    final contexto = ref.watch(sesionProvider).comercial;
    final ticket = ref.watch(ticketProvider).ticket;
    if (contexto == null) {
      if (ref.watch(productSaleProvider.select((s) => s.error)) != null) {
        return const SizedBox.shrink();
      }
      return const LinearProgressIndicator(
        semanticsLabel: 'Cargando configuración comercial',
      );
    }
    final tipos = contexto.tipos
        .where(
          (t) =>
              t['estado'] != false &&
              (t['idPuntoVenta'] == null ||
                  t['idPuntoVenta'] == ref.read(sesionProvider).office?.id),
        )
        .toList();
    final id = ticket.tipoPrecioCabeceraId ?? contexto.cabecera;
    final vigente = tipos.any((t) => t['id'] == id);
    void cambiarTipo(int? nuevoId) {
      final notifier = ref.read(ticketProvider.notifier);
      notifier.updateTicket(
        ref.read(ticketProvider).ticket.copyWith(tipoPrecioCabeceraId: nuevoId),
      );
    }

    final beneficios = <Widget>[
      if (estado.calculando && mostrarCalculando)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: LinearProgressIndicator(
            semanticsLabel: 'Calculando bonificaciones',
          ),
        ),
      if (_hayAlgo(estado)) _ResumenBonificaciones(estado: estado),
      if (estado.error != null)
        // En tarjeta para que se lea también sobre la cabecera azul.
        Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: 12, right: 4),
            leading: const Icon(Icons.error_outline),
            title: Text(estado.error!),
            trailing: TextButton(
              onPressed: () => ref
                  .read(bonificacionesProvider.notifier)
                  .programar(forzar: true),
              child: const Text('Reintentar'),
            ),
          ),
        ),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selectorCompacto && (contexto.activo || accionesCabecera != null))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                if (contexto.activo)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _TipoPrecioCompacto(
                        tipos: tipos,
                        id: vigente ? id : null,
                        onChanged: cambiarTipo,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                if (!contexto.activo) const Spacer(),
                if (accionesCabecera != null) accionesCabecera!,
              ],
            ),
          ),
        if (!selectorCompacto && mostrarSelector) const SelectorTipoPrecio(),
        if (beneficios.isNotEmpty)
          selectorCompacto
              // Sobre la cabecera azul, como el buscador: sin franja blanca de lado a lado.
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: ProgressIndicatorTheme(
                    data: const ProgressIndicatorThemeData(
                      color: Colors.white,
                      linearTrackColor: Colors.white24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: beneficios,
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: beneficios,
                ),
      ],
    );
  }
}

/// Desplegable del tipo de precio para nuevos productos (formulario completo).
class SelectorTipoPrecio extends ConsumerWidget {
  final String etiqueta;

  /// Se llama después de cambiar el tipo de precio (p. ej. para avisar).
  final ValueChanged<int?>? alCambiar;
  const SelectorTipoPrecio({
    super.key,
    this.etiqueta = 'Precio para nuevos productos',
    this.alCambiar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contexto = ref.watch(sesionProvider).comercial;
    if (contexto == null || !contexto.activo) return const SizedBox.shrink();
    final sede = ref.watch(sesionProvider).office?.id;
    final tipos = contexto.tipos
        .where(
          (t) =>
              t['estado'] != false &&
              (t['idPuntoVenta'] == null || t['idPuntoVenta'] == sede),
        )
        .toList();
    final id =
        ref.watch(
          ticketProvider.select((s) => s.ticket.tipoPrecioCabeceraId),
        ) ??
        contexto.cabecera;
    final vigente = tipos.any((t) => t['id'] == id);
    return DropdownButtonFormField<int>(
      key: ValueKey(id),
      isExpanded: true,
      initialValue: vigente ? id : null,
      hint: const Text('Elige un tipo disponible'),
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: etiqueta,
        contentPadding: const EdgeInsets.fromLTRB(12, 16, 8, 16),
      ),
      items: tipos
          .map(
            (t) => DropdownMenuItem<int>(
              value: (t['id'] as num).toInt(),
              child: Text('${t['nombre']}', overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (nuevoId) {
        final notifier = ref.read(ticketProvider.notifier);
        notifier.updateTicket(
          ref
              .read(ticketProvider)
              .ticket
              .copyWith(tipoPrecioCabeceraId: nuevoId),
        );
        alCambiar?.call(nuevoId);
      },
    );
  }
}

class _TipoPrecioCompacto extends StatelessWidget {
  final List<Map<String, dynamic>> tipos;
  final int? id;
  final ValueChanged<int?> onChanged;

  const _TipoPrecioCompacto({
    required this.tipos,
    required this.id,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final nombre =
        tipos.where((t) => t['id'] == id).firstOrNull?['nombre'] as String? ??
        'Elegir precio';
    return PopupMenuButton<int>(
      tooltip: 'Tipo de precio para nuevos productos',
      initialValue: id,
      onSelected: onChanged,
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 320),
      position: PopupMenuPosition.under,
      itemBuilder: (_) => tipos
          .map(
            (t) => CheckedPopupMenuItem<int>(
              value: (t['id'] as num).toInt(),
              checked: t['id'] == id,
              child: Text(
                '${t['nombre']}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44, maxWidth: 240),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .12),
          border: Border.all(color: Colors.white.withValues(alpha: .24)),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sell_outlined, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more, size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

bool _hayAlgo(BonificacionesState e) =>
    e.aplicadas.isNotEmpty ||
    e.elecciones.isNotEmpty ||
    e.conflictos.isNotEmpty ||
    e.bloqueos.isNotEmpty ||
    (e.resultado['noAplicadas'] as List? ?? []).isNotEmpty;

double _num(dynamic v) => (v as num?)?.toDouble() ?? 0;

String _unidad(dynamic u) {
  final t = '${u ?? ''}'.trim().toLowerCase();
  return t.isEmpty || t == 'niu' ? 'und' : t;
}

/// Motivo por el que las bonificaciones impiden enviar, o null si no hay.
String? motivoBonificaciones(BonificacionesState e) {
  if (e.error != null) return e.error;
  if (e.calculando || !e.vigente) {
    return 'Espera a que se calculen las bonificaciones.';
  }
  if (e.elecciones.isNotEmpty) {
    return 'Elige el regalo de "${e.elecciones.first['nombre']}".';
  }
  if (e.conflictos.isNotEmpty) {
    return 'Hay promociones que no se combinan: elige una en Bonificaciones.';
  }
  if (e.bloqueos.isNotEmpty) return '${e.bloqueos.first}';
  return null;
}

/// Una sola línea con lo importante; el detalle se abre en una hoja para no
/// empujar los productos del pedido fuera de la pantalla.
class _ResumenBonificaciones extends ConsumerWidget {
  final BonificacionesState estado;
  const _ResumenBonificaciones({required this.estado});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colores = Theme.of(context).colorScheme;
    final regalos = estado.resultado['regalos'] as Map? ?? {};
    final aplicadas = estado.aplicadas;
    final pendiente =
        estado.elecciones.isNotEmpty ||
        estado.conflictos.isNotEmpty ||
        estado.bloqueos.isNotEmpty;
    final titulo = aplicadas.isEmpty
        ? 'Bonificaciones'
        : aplicadas.length == 1
        ? '1 regalo'
        : '${aplicadas.length} regalos';
    final String detalle;
    if (estado.elecciones.isNotEmpty) {
      detalle = estado.elecciones.length == 1
          ? 'Falta elegir 1 regalo'
          : 'Falta elegir ${estado.elecciones.length} regalos';
    } else if (estado.conflictos.isNotEmpty) {
      detalle = 'Elige qué promoción aplicar';
    } else if (estado.bloqueos.isNotEmpty) {
      detalle = 'Sin stock para un regalo';
    } else if (aplicadas.isNotEmpty) {
      detalle = aplicadas
          .map(
            (a) =>
                '${cantidadPedido(_num(a['cantidadRegalo']))} ${regalos['${a['idProductoRegalo']}']?['nombre'] ?? 'regalo'}',
          )
          .join(' · ');
    } else {
      final cerca = (estado.resultado['noAplicadas'] as List? ?? []).first;
      // El motivo ya no trae el nombre: sin él no se sabe de qué promo es.
      final nombre = '${cerca['nombre'] ?? ''}'.trim();
      detalle = nombre.isEmpty
          ? '${cerca['motivo']}'
          : '$nombre: ${cerca['motivo']}';
    }
    void abrirDetalle() => showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: const _DetalleBonificaciones(),
      ),
    );
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: pendiente ? colores.errorContainer : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: abrirDetalle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            children: [
              Icon(
                pendiente ? Icons.error_outline : Icons.card_giftcard,
                color: pendiente ? colores.onErrorContainer : colores.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      detalle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: pendiente ? colores.onErrorContainer : null,
                      ),
                    ),
                  ],
                ),
              ),
              if (estado.elecciones.isNotEmpty)
                FilledButton.tonal(
                  onPressed: () => elegirRegaloBonificacion(
                    context,
                    ref,
                    estado.elecciones.first,
                  ),
                  child: const Text('Elegir'),
                )
              else if (estado.conflictos.isNotEmpty)
                FilledButton.tonal(
                  onPressed: abrirDetalle,
                  child: const Text('Elegir'),
                )
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> elegirRegaloBonificacion(
  BuildContext context,
  WidgetRef ref,
  dynamic eleccion,
) async {
  final regalos =
      ref.read(bonificacionesProvider).resultado['regalos'] as Map? ?? {};
  final opciones = eleccion['opciones'] as List;
  final elegido = await showModalBottomSheet<int>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: Text(
              'Elige el regalo',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            subtitle: Text(
              '${eleccion['nombre']} · ${cantidadPedido(_num(eleccion['cantidad']))} und',
            ),
          ),
          for (final dynamic id in opciones)
            ListTile(
              leading: const Icon(Icons.card_giftcard),
              title: Text('${regalos['$id']?['nombre'] ?? 'Producto $id'}'),
              subtitle: Text(
                regalos['$id']?['disponible'] == null
                    ? 'Stock por verificar'
                    : 'Disponible: ${cantidadPedido(_num(regalos['$id']['disponible']))} ${_unidad(regalos['$id']['unidad'])}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(ctx, (id as num).toInt()),
            ),
        ],
      ),
    ),
  );
  if (elegido != null) {
    ref
        .read(bonificacionesProvider.notifier)
        .elegirRegalo((eleccion['idPromocion'] as num).toInt(), elegido);
  }
}

/// Detalle vivo: se recalcula mientras la hoja está abierta.
class _DetalleBonificaciones extends ConsumerWidget {
  const _DetalleBonificaciones();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(bonificacionesProvider);
    final notifier = ref.read(bonificacionesProvider.notifier);
    final regalos = estado.resultado['regalos'] as Map? ?? {};
    final nombres = estado.resultado['nombresPromociones'] as Map? ?? {};
    final noAplicadas = estado.resultado['noAplicadas'] as List? ?? [];
    final estilo = Theme.of(context).textTheme;
    Widget seccion(String texto) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(texto, style: estilo.labelLarge),
    );
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .8,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text('Bonificaciones', style: estilo.titleMedium),
              trailing: IconButton(
                tooltip: 'Cerrar',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            if (estado.calculando) const LinearProgressIndicator(),
            if (estado.elecciones.isNotEmpty) seccion('Por elegir'),
            for (final dynamic e in estado.elecciones)
              ListTile(
                leading: const Icon(Icons.card_giftcard),
                title: Text('${e['nombre']}'),
                subtitle: Text(
                  'Regalo: ${cantidadPedido(_num(e['cantidad']))} und a elegir',
                ),
                trailing: FilledButton.tonal(
                  onPressed: () => elegirRegaloBonificacion(context, ref, e),
                  child: const Text('Elegir'),
                ),
              ),
            for (final dynamic grupo in estado.conflictos) ...[
              seccion('No se pueden combinar'),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Usan los mismos productos. Elige cuál aplicar en este pedido.',
                ),
              ),
              for (final dynamic id in grupo)
                ListTile(
                  leading: const Icon(Icons.radio_button_unchecked),
                  title: Text('${nombres['$id'] ?? 'Promoción $id'}'),
                  onTap: () => notifier.elegirPromocion(
                    List<dynamic>.from(grupo),
                    (id as num).toInt(),
                  ),
                ),
            ],
            if (estado.bloqueos.isNotEmpty) seccion('No se puede enviar'),
            for (final dynamic b in estado.bloqueos)
              ListTile(
                leading: Icon(
                  Icons.warning_amber,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text('$b', style: estilo.bodyMedium),
                subtitle: const Text(
                  'Repón stock del regalo o quita el producto que lo activa.',
                ),
              ),
            if (estado.aplicadas.isNotEmpty) seccion('Regalos'),
            for (final dynamic a in estado.aplicadas)
              ListTile(
                leading: const Icon(Icons.card_giftcard),
                title: Text(
                  '${cantidadPedido(_num(a['cantidadRegalo']))} und · ${regalos['${a['idProductoRegalo']}']?['nombre'] ?? 'Regalo'}',
                ),
                subtitle: Text('${a['nombre']}\n${a['explicacion'] ?? ''}'),
                isThreeLine: true,
                trailing: _accionesAplicada(notifier, a),
              ),
            if (noAplicadas.isNotEmpty) seccion('Aún no aplican'),
            for (final dynamic n in noAplicadas)
              ListTile(
                dense: true,
                leading: const Icon(Icons.info_outline),
                title: Text('${n['nombre']}'),
                subtitle: Text('${n['motivo']}'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget? _accionesAplicada(BonificacionesNotifier notifier, dynamic a) {
    final id = (a['idPromocion'] as num).toInt();
    final cambiarRegalo = notifier.selecciones.containsKey(id);
    final cambiarPromo = notifier.excluyentes.contains(id);
    if (!cambiarRegalo && !cambiarPromo) return null;
    return PopupMenuButton<String>(
      tooltip: 'Cambiar',
      icon: const Icon(Icons.swap_horiz),
      onSelected: (v) => v == 'regalo'
          ? notifier.cambiarRegalo(id)
          : notifier.liberarExcluyente(id),
      itemBuilder: (_) => [
        if (cambiarRegalo)
          const PopupMenuItem(value: 'regalo', child: Text('Cambiar regalo')),
        if (cambiarPromo)
          const PopupMenuItem(
            value: 'promo',
            child: Text('Usar otra promoción'),
          ),
      ],
    );
  }
}
