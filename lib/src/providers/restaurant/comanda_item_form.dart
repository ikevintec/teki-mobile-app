import 'package:teki_app/src/data/models/teki_model/command_detail_group_option.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail_preparation_option.dart';
import 'package:teki_app/src/data/models/teki_model/group.dart';
import 'package:teki_app/src/data/models/teki_model/group_option.dart';
import 'package:teki_app/src/data/models/teki_model/preparation_option.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';

/// Lógica pura del formulario de detalle de producto de la comanda:
/// validación de preparaciones/grupos, cálculo de extras y armado de las
/// opciones seleccionadas. Sin dependencias de UI — cubierta por tests en
/// `test/providers/comanda_item_form_test.dart`.
class ComandaItemForm {
  ComandaItemForm._();

  /// Valida las selecciones contra las reglas del producto (preparaciones
  /// requeridas, mínimos/máximos de grupos). Devuelve el mensaje de error,
  /// o null si todo es válido.
  static String? validate({
    required Product product,
    required Map<int, Set<int>> prepSelections,
    required Map<int, Set<int>> groupSelections,
    required Map<int, Map<int, int>> groupQuantities,
  }) {
    for (final pp in product.preparaciones ?? []) {
      if (pp.requerido == true) {
        final selected = prepSelections[pp.preparacion?.id] ?? const <int>{};
        if (selected.isEmpty) {
          return '"${pp.preparacion?.nombre ?? 'Preparación'}" es obligatoria';
        }
      }
    }
    for (final g in product.grupos ?? []) {
      final label = g.etiqueta ?? g.nombre ?? 'Adicional';
      final min = g.forzarMinimo;
      final max = g.forzarMaximo;

      if (g.requerido != true) continue;

      if (g.permitirCantidad == true) {
        final totalQty = (groupQuantities[g.id] ?? {}).values.fold<int>(
          0,
          (sum, q) => sum + q,
        );
        if (min != null && totalQty < min) {
          return '"$label" requiere al menos $min unidad(es) en total';
        }
        if (max != null && totalQty > max) {
          return '"$label" no puede superar $max unidad(es) en total';
        }
      } else {
        final selected = groupSelections[g.id] ?? {};
        final minCount = min ?? 1;
        if (selected.length < minCount) {
          return '"$label" requiere al menos $minCount selección(es)';
        }
      }
    }
    return null;
  }

  /// Total del item: (precio unitario + adicionales) × cantidad.
  /// Misma semántica que la web y que CartItem.totalPrice: los adicionales
  /// forman parte del precio UNITARIO, por lo que se multiplican por la
  /// cantidad del item. Ej: (20 + 5) × 2 = 50, no 20×2 + 5 = 45.
  static double totalPrice({
    required Product product,
    required double price,
    required int quantity,
    required Map<int, Set<int>> groupSelections,
    required Map<int, Map<int, int>> groupQuantities,
  }) {
    final extras = extrasPrice(
      product: product,
      groupSelections: groupSelections,
      groupQuantities: groupQuantities,
    );
    return (price + extras) * quantity;
  }

  /// Total de los adicionales seleccionados (precio × cantidad por opción).
  static double extrasPrice({
    required Product product,
    required Map<int, Set<int>> groupSelections,
    required Map<int, Map<int, int>> groupQuantities,
  }) {
    double extras = 0;
    for (final entry in groupSelections.entries) {
      final grupo = (product.grupos ?? []).firstWhere(
        (g) => g.id == entry.key,
        orElse: () => Group(),
      );
      for (final opId in entry.value) {
        final op = (grupo.opciones ?? []).firstWhere(
          (o) => o.id == opId,
          orElse: () => GroupOption(),
        );
        final qty = grupo.permitirCantidad == true
            ? (groupQuantities[entry.key]?[opId] ?? 1)
            : 1;
        extras += (op.precio ?? 0) * qty;
      }
    }
    return extras;
  }

  /// Alterna una opción de preparación y devuelve la nueva selección.
  /// - Selección múltiple: agrega o quita la opción (checkbox).
  /// - Selección única: reemplaza la anterior; tocar la ya marcada la
  ///   desmarca (mismo comportamiento que la web).
  static Set<int> togglePreparacion({
    required Set<int> current,
    required int opcionId,
    required bool seleccionMultiple,
  }) {
    final isSelected = current.contains(opcionId);
    if (seleccionMultiple) {
      return isSelected
          ? (Set<int>.of(current)..remove(opcionId))
          : (Set<int>.of(current)..add(opcionId));
    }
    return isSelected ? <int>{} : {opcionId};
  }

  /// Convierte las selecciones de preparaciones en las opciones del detalle:
  /// una entrada por opción marcada (varias por preparación si es de
  /// selección múltiple), en el orden en que la preparación define sus
  /// opciones.
  static List<CommandDetailPreparationOption> buildPreparacionOpciones({
    required Product product,
    required Map<int, Set<int>> prepSelections,
  }) {
    final preparacionOpciones = <CommandDetailPreparationOption>[];
    for (final pp in product.preparaciones ?? []) {
      final prepId = pp.preparacion?.id;
      if (prepId == null) continue;
      final selected = prepSelections[prepId] ?? const <int>{};
      if (selected.isEmpty) continue;
      for (final PreparationOption opcion in pp.preparacion?.opciones ?? []) {
        if (opcion.id == null || !selected.contains(opcion.id)) continue;
        preparacionOpciones.add(
          CommandDetailPreparationOption(
            idPreparacion: prepId,
            nombrePreparacion: pp.preparacion?.nombre,
            idOpcion: opcion.id,
            nombreOpcion: opcion.opcion,
          ),
        );
      }
    }
    return preparacionOpciones;
  }

  /// Resumen legible de las preparaciones agrupadas por preparación.
  /// Ej: ["TERMINO DE CARNE: TERMINO MEDIO, 3/4"].
  static List<String> preparacionesSummary(
    List<CommandDetailPreparationOption> opciones,
  ) {
    final byPrep = <String, List<String>>{};
    for (final o in opciones) {
      if (o.nombreOpcion == null) continue;
      byPrep
          .putIfAbsent(o.nombrePreparacion ?? '', () => [])
          .add(o.nombreOpcion!);
    }
    return byPrep.entries
        .map(
          (e) => e.key.isEmpty
              ? e.value.join(', ')
              : '${e.key}: ${e.value.join(', ')}',
        )
        .toList();
  }

  /// Convierte las selecciones de grupos/adicionales en las opciones del
  /// detalle, con cantidad y precio por opción.
  static List<CommandDetailGroupOption> buildGrupoOpciones({
    required Product product,
    required Map<int, Set<int>> groupSelections,
    required Map<int, Map<int, int>> groupQuantities,
  }) {
    final grupoOpciones = <CommandDetailGroupOption>[];
    for (final g in product.grupos ?? []) {
      final selectedIds = groupSelections[g.id] ?? {};
      for (final opcionId in selectedIds) {
        final opcion = (g.opciones ?? []).firstWhere(
          (o) => o.id == opcionId,
          orElse: () => GroupOption(),
        );
        final qty = g.permitirCantidad == true
            ? (groupQuantities[g.id]?[opcionId] ?? 1)
            : 1;
        grupoOpciones.add(
          CommandDetailGroupOption(
            idGrupo: g.id,
            nombreGrupo: g.nombre,
            idOpcion: opcionId,
            nombreOpcion: opcion.nombre,
            porcion: opcion.porcion ?? 1,
            precio: opcion.precio ?? 0,
            cantidad: qty.toDouble(),
            producto: opcion.producto,
          ),
        );
      }
    }
    return grupoOpciones;
  }
}
