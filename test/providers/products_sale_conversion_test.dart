import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail_group_option.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';

/// Reglas de conversión comanda → comprobante (paridad con la web,
/// emitir-comprobante.component.ts): los adicionales se expanden como
/// líneas propias con cantidad opción × cantidad item, y el precio base
/// del item sale del precioVenta persistido menos sus adicionales.
void main() {
  group('optionLineQuantity', () {
    test('caso reportado: 3 combos con 1 gaseosa c/u → 3 gaseosas', () {
      final detail = CommandDetail(cantidad: 3);
      final option = CommandDetailGroupOption(cantidad: 1, precio: 5.0);
      expect(optionLineQuantity(detail, option), 3.0);
    });

    test('opción con cantidad propia también multiplica', () {
      final detail = CommandDetail(cantidad: 2);
      final option = CommandDetailGroupOption(cantidad: 3, precio: 1.5);
      expect(optionLineQuantity(detail, option), 6.0);
    });

    test('valores nulos caen a 1', () {
      expect(
        optionLineQuantity(CommandDetail(), CommandDetailGroupOption()),
        1.0,
      );
    });
  });

  group('persistedBaseUnitPrice', () {
    test('resta los adicionales del precioVenta persistido (25-5=20)', () {
      final detail = CommandDetail(
        cantidad: 3,
        precioVenta: 25.0, // unitTotal guardado por la comanda: 20 + 5
        grupoProductoOpciones: [
          CommandDetailGroupOption(cantidad: 1, precio: 5.0),
        ],
      );
      expect(persistedBaseUnitPrice(detail), 20.0);
    });

    test('respeta precios editados por el mozo (23-5=18)', () {
      final detail = CommandDetail(
        cantidad: 1,
        precioVenta: 23.0,
        grupoProductoOpciones: [
          CommandDetailGroupOption(cantidad: 1, precio: 5.0),
        ],
      );
      expect(persistedBaseUnitPrice(detail), 18.0);
    });

    test('ignora adicionales eliminados', () {
      final detail = CommandDetail(
        precioVenta: 25.0,
        grupoProductoOpciones: [
          CommandDetailGroupOption(cantidad: 1, precio: 5.0),
          CommandDetailGroupOption(cantidad: 1, precio: 3.0, eliminado: true),
        ],
      );
      expect(persistedBaseUnitPrice(detail), 20.0);
    });

    test('sin precio persistido devuelve null (fallback a catálogo)', () {
      expect(persistedBaseUnitPrice(CommandDetail()), isNull);
      expect(persistedBaseUnitPrice(CommandDetail(precioVenta: 0)), isNull);
    });

    test('base no positiva devuelve null (dato corrupto → catálogo)', () {
      final detail = CommandDetail(
        precioVenta: 4.0,
        grupoProductoOpciones: [
          CommandDetailGroupOption(cantidad: 1, precio: 5.0),
        ],
      );
      expect(persistedBaseUnitPrice(detail), isNull);
    });
  });

  group('consistencia del caso reportado completo', () {
    test('3 combos (base 20) + gaseosa 5 c/u → 20×3 + 5×3 = 75', () {
      final detail = CommandDetail(
        cantidad: 3,
        precioVenta: 25.0,
        grupoProductoOpciones: [
          CommandDetailGroupOption(cantidad: 1, precio: 5.0),
        ],
      );
      final base = persistedBaseUnitPrice(detail)!;
      final optQty = optionLineQuantity(
          detail, detail.grupoProductoOpciones!.first);
      final total = base * (detail.cantidad ?? 1) +
          (detail.grupoProductoOpciones!.first.precio ?? 0) * optQty;
      expect(total, 75.0); // lo que muestra la web — no 65
    });
  });
}
