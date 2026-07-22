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
    required Map<int, int?> prepSelections,
    required Map<int, Set<int>> groupSelections,
    required Map<int, Map<int, int>> groupQuantities,
  }) {
    for (final pp in product.preparaciones ?? []) {
      if (pp.requerido == true) {
        final selected = prepSelections[pp.preparacion?.id];
        if (selected == null) {
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
        final totalQty = (groupQuantities[g.id] ?? {})
            .values
            .fold<int>(0, (sum, q) => sum + q);
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

  /// Convierte las selecciones de preparaciones en las opciones del detalle.
  static List<CommandDetailPreparationOption> buildPreparacionOpciones({
    required Product product,
    required Map<int, int?> prepSelections,
  }) {
    final preparacionOpciones = <CommandDetailPreparationOption>[];
    for (final pp in product.preparaciones ?? []) {
      final prepId = pp.preparacion?.id;
      final opcionId = prepSelections[prepId];
      if (prepId != null && opcionId != null) {
        final opcion = (pp.preparacion?.opciones ?? []).firstWhere(
          (o) => o.id == opcionId,
          orElse: () => PreparationOption(),
        );
        preparacionOpciones.add(CommandDetailPreparationOption(
          idPreparacion: prepId,
          nombrePreparacion: pp.preparacion?.nombre,
          idOpcion: opcionId,
          nombreOpcion: opcion.opcion,
        ));
      }
    }
    return preparacionOpciones;
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
        grupoOpciones.add(CommandDetailGroupOption(
          idGrupo: g.id,
          nombreGrupo: g.nombre,
          idOpcion: opcionId,
          nombreOpcion: opcion.nombre,
          porcion: opcion.porcion ?? 1,
          precio: opcion.precio ?? 0,
          cantidad: qty.toDouble(),
          producto: opcion.producto,
        ));
      }
    }
    return grupoOpciones;
  }
}
