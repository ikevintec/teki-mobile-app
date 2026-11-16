import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/providers/config/config.dart';

class SelectorPrecioComercial extends ConsumerWidget {
  const SelectorPrecioComercial({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider);
    if (sesion.distribuidor['preciosComerciales'] != true) {
      return const SizedBox.shrink();
    }
    final tipos =
        List<Map<String, dynamic>>.from(sesion.distribuidor['tipos'] ?? [])
            .where(
              (t) =>
                  t['estado'] == true &&
                  (t['idPuntoVenta'] == null ||
                      t['idPuntoVenta'] == sesion.office?.id),
            )
            .toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: DropdownButtonFormField<int>(
        key: ValueKey(sesion.distribuidor['tipoPrecioCabeceraId']),
        initialValue:
            tipos.any(
              (t) => t['id'] == sesion.distribuidor['tipoPrecioCabeceraId'],
            )
            ? sesion.distribuidor['tipoPrecioCabeceraId']
            : null,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Precio para nuevos productos',
          filled: true,
        ),
        items: tipos
            .map(
              (t) => DropdownMenuItem<int>(
                value: t['id'],
                child: Text(t['nombre']),
              ),
            )
            .toList(),
        onChanged: (id) =>
            ref.read(sesionProvider.notifier).elegirTipoComercial(id),
      ),
    );
  }
}
