import 'package:teki_app/src/providers/products/profucts.dart';

Map<String, dynamic> buildProductQueryParams(ProductsState state) {
  return {
    if (state.pageNumber != null) 'pageNumber': state.pageNumber,
    if (state.paginacion != null) 'paginacion': state.paginacion,
    if (state.perPage != null) 'perPage': state.perPage,
    if (state.sortField != null) 'sortField': state.sortField,
    if (state.sortOrder != null) 'sortOrder': state.sortOrder,
    if (state.filterGlobal != null) 'filterGlobal': state.filterGlobal,
    if (state.codigo != null) 'codigo': state.codigo,
    if (state.codigoBarra != null) 'codigoBarra': state.codigoBarra,
    if (state.nombre != null) 'nombre': state.nombre,
    if (state.tipo != null && state.tipo!.isNotEmpty) 'tipo': state.tipo,
    if (state.idMarca != null) 'idMarca': state.idMarca,
    if (state.codigoMoneda != null) 'codigoMoneda': state.codigoMoneda,
    if (state.idCategoria != null && state.idCategoria!.isNotEmpty) 'idCategoria': state.idCategoria,
    if (state.mostrarEnRestaurante != null) 'mostrarEnRestaurante': state.mostrarEnRestaurante,
    if (state.mostrarEnWeb != null) 'mostrarEnWeb': state.mostrarEnWeb,
    if (state.favorito != null) 'favorito': state.favorito,
    if (state.idPuntoVenta != null) 'idPuntoVenta': state.idPuntoVenta,
    if (state.idPuntoVentaOrder != null) 'idPuntoVentaOrder': state.idPuntoVentaOrder,
    if (state.limit != null) 'limit': state.limit,
  };
}
