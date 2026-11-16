import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/distribuidor/beneficios_venta.dart';

class BeneficiosVenta extends ConsumerWidget {
  const BeneficiosVenta({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(sesionProvider).distribuidor['promociones'] != true) {
      return const SizedBox.shrink();
    }
    final estado = ref.watch(beneficiosVentaProvider), r = estado.resultado;
    final notifier = ref.read(beneficiosVentaProvider.notifier);
    if (r.isEmpty && !estado.cargando && estado.error == null) {
      return const SizedBox.shrink();
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 180),
      child: SingleChildScrollView(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Beneficios',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (estado.cargando) const LinearProgressIndicator(),
                if (estado.error != null)
                  Row(
                    children: [
                      Expanded(child: Text(estado.error!)),
                      TextButton(
                        onPressed: () => notifier.evaluar(forzar: true),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                for (final e in (r['eleccionesPendientes'] as List? ?? []))
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    decoration: InputDecoration(labelText: e['nombre']),
                    hint: Text('Elige ${e['cantidad']} de regalo'),
                    items: [
                      for (final id in e['opciones'])
                        DropdownMenuItem<int>(
                          value: id,
                          child: Text(estado.nombres[id] ?? 'Producto $id'),
                        ),
                    ],
                    onChanged: (id) {
                      if (id != null) {
                        notifier.elegirRegalo(e['idPromocion'], id);
                      }
                    },
                  ),
                for (final grupo in (r['conflictos'] as List? ?? []))
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final id in grupo)
                        OutlinedButton(
                          onPressed: () => notifier.elegirPromocion(
                            id,
                            List<dynamic>.from(grupo),
                          ),
                          child: Text(
                            r['nombresPromociones']?['$id'] ?? 'Promoción $id',
                          ),
                        ),
                    ],
                  ),
                for (final a in (r['aplicadas'] as List? ?? []))
                  Text('${a['nombre']} · ${a['cantidadRegalo']} de regalo'),
                for (final n in (r['noAplicadas'] as List? ?? []))
                  Text('${n['nombre']}: ${n['motivo']}'),
                for (final b in (r['bloqueos'] as List? ?? []))
                  Text(b.toString()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
