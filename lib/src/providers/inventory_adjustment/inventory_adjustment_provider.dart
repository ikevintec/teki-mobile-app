import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/data/models/teki_model/batch_product.dart';
import 'package:teki_app/src/data/models/teki_model/inventory_adjustment.dart';
import 'package:teki_app/src/data/models/teki_model/inventory_adjustment_detail.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/repositories/inventory_adjustment_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/inventory_adjustment_repository.dart';
import 'package:teki_app/src/utils/notifications.dart';

// Representa un lote/serie en el formulario de ajuste
class AdjustmentLoteItem {
  final int? id;
  final String nombre; // maps to BatchProduct.serie
  final double cantidad;
  final double? precioCompra;
  final String tipoLote; // 'SERIE' | 'LOTE'
  final bool isExisting;

  AdjustmentLoteItem({
    this.id,
    required this.nombre,
    this.cantidad = 1,
    this.precioCompra,
    required this.tipoLote,
    this.isExisting = false,
  });

  AdjustmentLoteItem copyWith({
    int? id,
    String? nombre,
    double? cantidad,
    double? precioCompra,
    String? tipoLote,
    bool? isExisting,
  }) => AdjustmentLoteItem(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    cantidad: cantidad ?? this.cantidad,
    precioCompra: precioCompra ?? this.precioCompra,
    tipoLote: tipoLote ?? this.tipoLote,
    isExisting: isExisting ?? this.isExisting,
  );
}

// Representa un ítem en el formulario de ajuste
class AdjustmentFormItem {
  final Product product;

  /// Stock objetivo que el usuario ingresa directamente
  final double nuevoStock;
  final String concepto;
  final List<AdjustmentLoteItem> lotes;

  /// Stock del producto en el punto de venta ANTES del ajuste
  final double stockActual;

  AdjustmentFormItem({
    required this.product,
    double? nuevoStock,
    this.concepto = 'AJUSTE',
    this.lotes = const [],
    this.stockActual = 0,
  }) : nuevoStock = nuevoStock ?? stockActual;

  /// Diferencia: positivo = entrada, negativo = salida
  double get delta => nuevoStock - stockActual;

  /// Tipo calculado automáticamente según el delta
  String get tipo => delta >= 0 ? 'ENTRADA' : 'SALIDA';

  /// Cantidad absoluta a enviar al API
  double get cantidad => delta.abs();

  double get cantidadEfectiva => cantidad;

  /// Alias para compatibilidad con el chip y validación
  double get stockNuevo => nuevoStock;

  /// Suma de TODOS los lotes (existentes + nuevos)
  double get sumAllLotes => lotes.fold(0.0, (s, l) => s + l.cantidad);

  AdjustmentFormItem copyWith({
    Product? product,
    double? nuevoStock,
    String? concepto,
    List<AdjustmentLoteItem>? lotes,
    double? stockActual,
  }) => AdjustmentFormItem(
    product: product ?? this.product,
    nuevoStock: nuevoStock ?? this.nuevoStock,
    concepto: concepto ?? this.concepto,
    lotes: lotes ?? this.lotes,
    stockActual: stockActual ?? this.stockActual,
  );
}

final inventoryAdjustmentProvider =
    StateNotifierProvider<
      InventoryAdjustmentNotifier,
      InventoryAdjustmentFormState
    >(
      (ref) => InventoryAdjustmentNotifier(
        adjustmentRepository: InventoryAdjustmentRepositoryImpl(),
      ),
    );

class InventoryAdjustmentNotifier
    extends StateNotifier<InventoryAdjustmentFormState> {
  final InventoryAdjustmentRepository adjustmentRepository;

  InventoryAdjustmentNotifier({required this.adjustmentRepository})
    : super(
        InventoryAdjustmentFormState(
          items: [],
          motivo: '',
          observacion: '',
          isSubmitting: false,
          success: false,
        ),
      );

  void addItem(
    Product product, {
    List<BatchProduct> existingLotes = const [],
    double stockActual = 0,
  }) {
    final alreadyAdded = state.items.any((i) => i.product.id == product.id);
    if (alreadyAdded) {
      warningNotification('El producto ya fue agregado');
      return;
    }
    final lotes = existingLotes
        .map(
          (l) => AdjustmentLoteItem(
            id: l.id,
            nombre: l.serie ?? '',
            cantidad: l.cantidad ?? 1,
            precioCompra: l.precioCompra,
            tipoLote: l.tipoLote ?? 'SERIE',
            isExisting: true,
          ),
        )
        .toList();
    state = state.copyWith(
      items: [
        ...state.items,
        AdjustmentFormItem(
          product: product,
          lotes: lotes,
          stockActual: stockActual,
          nuevoStock: stockActual, // empieza pre-cargado con el stock actual
        ),
      ],
    );
  }

  void removeItem(int index) {
    final updated = [...state.items];
    updated.removeAt(index);
    state = state.copyWith(items: updated);
  }

  void updateNuevoStock(int index, double nuevoStock) {
    final updated = [...state.items];
    updated[index] = updated[index].copyWith(nuevoStock: nuevoStock);
    state = state.copyWith(items: updated);
  }

  void updateConcepto(int index, String concepto) {
    final updated = [...state.items];
    updated[index] = updated[index].copyWith(concepto: concepto);
    state = state.copyWith(items: updated);
  }

  /// Agrega un lote a un ítem. Valida que el nombre no sea duplicado.
  void addLote(int itemIndex, AdjustmentLoteItem lote) {
    final updated = [...state.items];
    final item = updated[itemIndex];
    final duplicate = item.lotes.any(
      (l) => l.nombre.toLowerCase() == lote.nombre.toLowerCase(),
    );
    if (duplicate) {
      warningNotification('El nombre ya está registrado en los lotes');
      return;
    }
    updated[itemIndex] = item.copyWith(lotes: [lote, ...item.lotes]);
    state = state.copyWith(items: updated);
  }

  /// Elimina un lote (solo los que no son existentes)
  void removeLote(int itemIndex, int loteIndex) {
    final updated = [...state.items];
    final item = updated[itemIndex];
    if (item.lotes[loteIndex].isExisting) return;
    final updatedLotes = [...item.lotes]..removeAt(loteIndex);
    updated[itemIndex] = item.copyWith(lotes: updatedLotes);
    state = state.copyWith(items: updated);
  }

  void updateLoteCantidad(int itemIndex, int loteIndex, double cantidad) {
    final updated = [...state.items];
    final item = updated[itemIndex];
    final updatedLotes = [...item.lotes];
    updatedLotes[loteIndex] = updatedLotes[loteIndex].copyWith(
      cantidad: cantidad,
    );
    updated[itemIndex] = item.copyWith(lotes: updatedLotes);
    state = state.copyWith(items: updated);
  }

  void updateLoteNombre(int itemIndex, int loteIndex, String nombre) {
    final updated = [...state.items];
    final item = updated[itemIndex];
    final updatedLotes = [...item.lotes];
    updatedLotes[loteIndex] = updatedLotes[loteIndex].copyWith(nombre: nombre);
    updated[itemIndex] = item.copyWith(lotes: updatedLotes);
    state = state.copyWith(items: updated);
  }

  void updateLotePrecio(int itemIndex, int loteIndex, double? precio) {
    final updated = [...state.items];
    final item = updated[itemIndex];
    final updatedLotes = [...item.lotes];
    updatedLotes[loteIndex] = updatedLotes[loteIndex].copyWith(
      precioCompra: precio,
    );
    updated[itemIndex] = item.copyWith(lotes: updatedLotes);
    state = state.copyWith(items: updated);
  }

  void setMotivo(String motivo) => state = state.copyWith(motivo: motivo);
  void setObservacion(String obs) => state = state.copyWith(observacion: obs);

  Future<void> submit(int idPuntoVenta) async {
    if (state.items.isEmpty) {
      warningNotification('Agregue al menos un producto');
      return;
    }

    // Validación por ítem
    bool hasLoteError = false;
    for (final item in state.items) {
      if (item.nuevoStock < 0) {
        warningNotification('El nuevo stock no puede ser negativo');
        return;
      }
      if (item.product.validacionLote == true) {
        if (loteValidationError(item) != null) {
          hasLoteError = true;
        }
      } else {
        if (item.cantidad == 0) {
          warningNotification(
            'El nuevo stock debe ser diferente al stock actual',
          );
          return;
        }
      }
    }
    // Errores de lotes: mostrar inline en la UI, no como notificación
    if (hasLoteError) {
      state = state.copyWith(showValidation: true);
      return;
    }

    if (state.motivo.trim().isEmpty) {
      warningNotification('El motivo es obligatorio');
      return;
    }

    state = state.copyWith(isSubmitting: true);
    try {
      final adjustment = InventoryAdjustment(
        puntoVenta: Office(id: idPuntoVenta),
        motivo: state.motivo.isEmpty ? null : state.motivo,
        observacion: state.observacion.isEmpty ? null : state.observacion,
        items: state.items.map((i) {
          List<BatchProduct>? batchLotes;
          if (i.product.validacionLote == true && i.lotes.isNotEmpty) {
            batchLotes = i.lotes
                .map(
                  (l) => BatchProduct(
                    id: l.id,
                    cantidad: l.cantidad,
                    tipoLote: l.tipoLote,
                    serie: l.nombre,
                    precioCompra: l.precioCompra,
                  ),
                )
                .toList();
          }
          return InventoryAdjustmentDetail(
            producto: i.product,
            tipo: i.tipo,
            cantidad: i.cantidadEfectiva,
            concepto: i.concepto.isEmpty ? null : i.concepto,
            lotes: batchLotes,
          );
        }).toList(),
      );

      await adjustmentRepository.saveAdjustment(adjustment);
      state = state.copyWith(isSubmitting: false, success: true);
      successNotification('Ajuste registrado correctamente');
      reset();
      // Vuelve a la pantalla que abrió el ajuste (tab Inventario del dashboard
      // o /inventory). NO usar Get.until con un nombre de ruta fijo: el tab del
      // dashboard no empuja /inventory, así que no había coincidencia y se
      // vaciaba el stack completo dejando pantalla negra.
      if (Get.key.currentState?.canPop() ?? false) {
        Get.back(result: true);
      }
    } catch (e) {
      state = state.copyWith(isSubmitting: false);
      errorNotification(e.toString());
    }
  }

  /// Retorna el mensaje de error de validación de lotes para un ítem, o null si es válido.
  /// Solo aplica cuando validacionLote == true.
  String? loteValidationError(AdjustmentFormItem item) {
    if (item.product.validacionLote != true) return null;
    if (item.nuevoStock < 0) return 'El nuevo stock no puede ser negativo';
    if (item.cantidad == 0) {
      return 'El nuevo stock debe ser diferente al stock actual';
    }
    if (item.lotes.any((l) => l.cantidad < 0)) {
      return 'La cantidad de cada lote no puede ser negativa';
    }
    final sum = item.sumAllLotes;
    final expected = item.nuevoStock;
    if ((sum - expected).abs() > 0.001) {
      return 'Suma de lotes (${_fmt(sum)}) ≠ stock nuevo (${_fmt(expected)})';
    }
    return null;
  }

  void reset() {
    state = InventoryAdjustmentFormState(
      items: [],
      motivo: '',
      observacion: '',
      isSubmitting: false,
      success: false,
      showValidation: false,
    );
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}

class InventoryAdjustmentFormState {
  final List<AdjustmentFormItem> items;
  final String motivo;
  final String observacion;
  final bool isSubmitting;
  final bool success;
  final bool showValidation;

  InventoryAdjustmentFormState({
    required this.items,
    required this.motivo,
    required this.observacion,
    required this.isSubmitting,
    required this.success,
    this.showValidation = false,
  });

  InventoryAdjustmentFormState copyWith({
    List<AdjustmentFormItem>? items,
    String? motivo,
    String? observacion,
    bool? isSubmitting,
    bool? success,
    bool? showValidation,
  }) => InventoryAdjustmentFormState(
    items: items ?? this.items,
    motivo: motivo ?? this.motivo,
    observacion: observacion ?? this.observacion,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    success: success ?? this.success,
    showValidation: showValidation ?? this.showValidation,
  );
}
