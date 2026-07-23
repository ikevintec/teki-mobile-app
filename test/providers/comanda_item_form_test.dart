import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/group.dart';
import 'package:teki_app/src/data/models/teki_model/group_option.dart';
import 'package:teki_app/src/data/models/teki_model/preparation.dart';
import 'package:teki_app/src/data/models/teki_model/preparation_option.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/product_preparation.dart';
import 'package:teki_app/src/providers/restaurant/comanda_item_form.dart';


Product productoConGrupoGlobal({
  bool requerido = true,
  bool? permitirCantidad,
  int? forzarMinimo,
  int? forzarMaximo,
}) {
  return Product(grupos: [
    Group(
      id: 5,
      nombre: 'Cremas',
      requerido: requerido,
      permitirCantidad: permitirCantidad,
      forzarMinimo: forzarMinimo,
      forzarMaximo: forzarMaximo,
      opciones: [
        GroupOption(id: 51, nombre: 'Ají', precio: 1.5),
        GroupOption(id: 52, nombre: 'Mayonesa', precio: 0),
      ],
    ),
  ]);
}

void main() {
  final productoConPreparacion = Product(preparaciones: [
    ProductPreparation(
      requerido: true,
      preparacion: Preparation(
        id: 1,
        nombre: 'Término',
        opciones: [
          PreparationOption(id: 11, opcion: 'Medio'),
          PreparationOption(id: 12, opcion: 'Bien cocido'),
        ],
      ),
    ),
  ]);

  Product productoConGrupo({
    bool requerido = true,
    bool? permitirCantidad,
    int? forzarMinimo,
    int? forzarMaximo,
  }) {
    return Product(grupos: [
      Group(
        id: 5,
        nombre: 'Cremas',
        requerido: requerido,
        permitirCantidad: permitirCantidad,
        forzarMinimo: forzarMinimo,
        forzarMaximo: forzarMaximo,
        opciones: [
          GroupOption(id: 51, nombre: 'Ají', precio: 1.5),
          GroupOption(id: 52, nombre: 'Mayonesa', precio: 0),
        ],
      ),
    ]);
  }

  group('ComandaItemForm.validate', () {
    test('preparación requerida sin selección devuelve error', () {
      final error = ComandaItemForm.validate(
        product: productoConPreparacion,
        prepSelections: {},
        groupSelections: {},
        groupQuantities: {},
      );
      expect(error, '"Término" es obligatoria');
    });

    test('preparación requerida con selección es válida', () {
      final error = ComandaItemForm.validate(
        product: productoConPreparacion,
        prepSelections: {1: 11},
        groupSelections: {},
        groupQuantities: {},
      );
      expect(error, isNull);
    });

    test('grupo requerido sin selección exige el mínimo (default 1)', () {
      final error = ComandaItemForm.validate(
        product: productoConGrupo(),
        prepSelections: {},
        groupSelections: {5: {}},
        groupQuantities: {},
      );
      expect(error, '"Cremas" requiere al menos 1 selección(es)');
    });

    test('grupo no requerido no valida mínimos', () {
      final error = ComandaItemForm.validate(
        product: productoConGrupo(requerido: false),
        prepSelections: {},
        groupSelections: {5: {}},
        groupQuantities: {},
      );
      expect(error, isNull);
    });

    test('grupo con permitirCantidad valida mínimo y máximo del total', () {
      final producto = productoConGrupo(
          permitirCantidad: true, forzarMinimo: 2, forzarMaximo: 3);

      expect(
        ComandaItemForm.validate(
          product: producto,
          prepSelections: {},
          groupSelections: {
            5: {51}
          },
          groupQuantities: {
            5: {51: 1}
          },
        ),
        '"Cremas" requiere al menos 2 unidad(es) en total',
      );

      expect(
        ComandaItemForm.validate(
          product: producto,
          prepSelections: {},
          groupSelections: {
            5: {51}
          },
          groupQuantities: {
            5: {51: 4}
          },
        ),
        '"Cremas" no puede superar 3 unidad(es) en total',
      );

      expect(
        ComandaItemForm.validate(
          product: producto,
          prepSelections: {},
          groupSelections: {
            5: {51, 52}
          },
          groupQuantities: {
            5: {51: 1, 52: 1}
          },
        ),
        isNull,
      );
    });
  });

  group('ComandaItemForm.extrasPrice', () {
    test('suma precio × cantidad de las opciones seleccionadas', () {
      final producto = productoConGrupo(permitirCantidad: true);
      final total = ComandaItemForm.extrasPrice(
        product: producto,
        groupSelections: {
          5: {51, 52}
        },
        groupQuantities: {
          5: {51: 3, 52: 2}
        },
      );
      expect(total, 4.5); // 1.5×3 + 0×2
    });

    test('sin permitirCantidad cada opción cuenta una vez', () {
      final total = ComandaItemForm.extrasPrice(
        product: productoConGrupo(),
        groupSelections: {
          5: {51}
        },
        groupQuantities: {},
      );
      expect(total, 1.5);
    });

    test('sin selecciones el total es cero', () {
      expect(
        ComandaItemForm.extrasPrice(
          product: productoConGrupo(),
          groupSelections: {},
          groupQuantities: {},
        ),
        0,
      );
    });
  });

  group('ComandaItemForm.buildPreparacionOpciones', () {
    test('mapea la selección con nombres de preparación y opción', () {
      final opciones = ComandaItemForm.buildPreparacionOpciones(
        product: productoConPreparacion,
        prepSelections: {1: 12},
      );
      expect(opciones, hasLength(1));
      expect(opciones.first.idPreparacion, 1);
      expect(opciones.first.nombrePreparacion, 'Término');
      expect(opciones.first.idOpcion, 12);
      expect(opciones.first.nombreOpcion, 'Bien cocido');
    });

    test('sin selección devuelve lista vacía', () {
      expect(
        ComandaItemForm.buildPreparacionOpciones(
          product: productoConPreparacion,
          prepSelections: {},
        ),
        isEmpty,
      );
    });
  });

  group('ComandaItemForm.buildGrupoOpciones', () {
    test('mapea opciones con cantidad para grupos permitirCantidad', () {
      final opciones = ComandaItemForm.buildGrupoOpciones(
        product: productoConGrupo(permitirCantidad: true),
        groupSelections: {
          5: {51}
        },
        groupQuantities: {
          5: {51: 3}
        },
      );
      expect(opciones, hasLength(1));
      expect(opciones.first.idGrupo, 5);
      expect(opciones.first.nombreOpcion, 'Ají');
      expect(opciones.first.precio, 1.5);
      expect(opciones.first.cantidad, 3.0);
    });

    test('sin permitirCantidad la cantidad es 1', () {
      final opciones = ComandaItemForm.buildGrupoOpciones(
        product: productoConGrupo(),
        groupSelections: {
          5: {52}
        },
        groupQuantities: {},
      );
      expect(opciones.first.cantidad, 1.0);
      expect(opciones.first.nombreOpcion, 'Mayonesa');
    });
  });

  group('ComandaItemForm.totalPrice', () {
    test('los adicionales multiplican por la cantidad del item (bug 45 vs 50)', () {
      // Caso reportado: combo S/.20, cantidad 2, adicional coca cola S/.5
      final producto = Product(grupos: [
        Group(
          id: 5,
          nombre: 'Agrega gaseosa',
          requerido: true,
          forzarMinimo: 1,
          forzarMaximo: 1,
          opciones: [GroupOption(id: 51, nombre: 'coca cola 1/2', precio: 5.0)],
        ),
      ]);
      final total = ComandaItemForm.totalPrice(
        product: producto,
        price: 20.0,
        quantity: 2,
        groupSelections: {
          5: {51}
        },
        groupQuantities: {},
      );
      expect(total, 50.0); // (20 + 5) × 2 — igual que la web y CartItem.totalPrice
    });

    test('sin adicionales: precio × cantidad', () {
      final total = ComandaItemForm.totalPrice(
        product: Product(),
        price: 20.0,
        quantity: 3,
        groupSelections: {},
        groupQuantities: {},
      );
      expect(total, 60.0);
    });

    test('con cantidades de opción tambien multiplica por el item', () {
      final producto = productoConGrupoGlobal(permitirCantidad: true);
      final total = ComandaItemForm.totalPrice(
        product: producto,
        price: 10.0,
        quantity: 2,
        groupSelections: {
          5: {51}
        },
        groupQuantities: {
          5: {51: 3}
        },
      );
      expect(total, (10.0 + 1.5 * 3) * 2); // 29.0
    });
  });
}
