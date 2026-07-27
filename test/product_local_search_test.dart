import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/providers/sale/products/helpers/product_local_search.dart';

ProductSearchEntry entry(
  int position,
  String nombre, {
  String codigo = '',
  String codigoBarra = '',
  int createdOn = 0,
}) =>
    ProductSearchEntry(
      position: position,
      nombre: nombre.toLowerCase(),
      codigo: codigo.toLowerCase(),
      codigoBarra: codigoBarra.toLowerCase(),
      createdOn: createdOn,
    );

void main() {
  final catalogo = [
    entry(0, 'Coca Cola 500ml',
        codigo: 'CC500', codigoBarra: '7501055300006', createdOn: 100),
    entry(1, 'Inca Kola 500ml',
        codigo: 'IK500', codigoBarra: '7751271000011', createdOn: 200),
    entry(2, 'Galleta Oreo',
        codigo: 'GO100', codigoBarra: '7622210951045', createdOn: 300),
    entry(3, 'Café Altomayo 250g', codigo: 'CA250', createdOn: 400),
    entry(4, 'Coca Cola Zero 1.5L', codigo: 'CCZ15', createdOn: 500),
  ];

  test('la coincidencia directa va primero, ordenada por createdOn desc', () {
    expect(runProductSearch(catalogo, 'coca cola'), [4, 0]);
  });

  test('el orden replica el de la web (caso "pal")', () {
    // Los 5 son coincidencia directa: municiPAL, PALabras, PALma, PALito.
    final productos = [
      entry(0, 'Aceite vegetal 1L Palma Real',
          codigo: 'AVPR01', createdOn: 1683863639577),
      entry(1, '1 PALITO DE ANTICUCHO', createdOn: 1683863639271),
      entry(2, 'MÓJAME LAS PALABRAS', createdOn: 1683863646180),
      entry(3, 'CAMISETA DEPORTIVO MUNICIPAL OFICIAL 2022 AAA L',
          codigoBarra: 'C1777', createdOn: 1684298143211),
      entry(4, 'CAMISETA DEPORTIVO MUNICIPAL OFICIAL 2022 AAA S',
          codigoBarra: 'C1778', createdOn: 1684298143227),
    ];
    expect(runProductSearch(productos, 'pal'), [4, 3, 2, 0, 1]);
  });

  test('busca por codigo y por codigo de barras', () {
    expect(runProductSearch(catalogo, 'ccz15'), [4]);
    expect(runProductSearch(catalogo, '7622210951045'), [2]);
  });

  test('normaliza igual que la web: trim + lowercase, sin quitar tildes', () {
    expect(runProductSearch(catalogo, '  CAFÉ  '), [3]);
    // "cafe" sin tilde no es coincidencia directa; solo puede salir por fuzzy.
    expect(runProductSearch(catalogo, 'cafe'), contains(3));
  });

  test('el fuzzy atrapa typos que el includes no', () {
    expect(runProductSearch(catalogo, 'galetta'), contains(2));
  });

  test('tokens separados por espacio se combinan como AND (extended search)',
      () {
    // "coca 500" no es substring de ningun nombre: entra por fuzzy con AND.
    final resultados = runProductSearch(catalogo, 'coca 500');
    expect(resultados, contains(0));
    expect(resultados, isNot(contains(2)));
  });

  test('respeta el limite de resultados', () {
    expect(runProductSearch(catalogo, 'o', limit: 2).length, 2);
  });

  test('query vacia no devuelve nada', () {
    expect(runProductSearch(catalogo, '   '), isEmpty);
  });

  test('rendimiento sobre 20k productos', () {
    final grande = [
      for (var i = 0; i < 20000; i++)
        entry(i, 'Producto de prueba numero $i',
            codigo: 'P$i', codigoBarra: '77512710000$i'),
    ];

    // Caso comun: el grupo directo llena el limite y el fuzzy ni se ejecuta.
    final directo = Stopwatch()..start();
    final rapido = runProductSearch(grande, 'prueba numero 1');
    directo.stop();
    expect(rapido.length, kLocalSearchMaxResults);

    final difuso = Stopwatch()..start();
    final peor = runProductSearch(grande, 'prodcuto zzz');
    difuso.stop();

    // ignore: avoid_print
    print('directo: ${directo.elapsedMilliseconds}ms · '
        'fuzzy full-scan: ${difuso.elapsedMilliseconds}ms · '
        'resultados: ${peor.length}');
  });
}
