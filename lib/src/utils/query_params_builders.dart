
Map<String, dynamic> buildProductQueryParams(dynamic state) {
  final Map<String, dynamic> params = {};

  void safeAdd(String key, dynamic value) {
    if (value != null) params[key] = value;
  }

  safeAdd('pageNumber', state.pageNumber);
  safeAdd('paginacion', state.paginacion);
  safeAdd('perPage', state.perPage);
  safeAdd('sortField', state.sortField);
  safeAdd('sortOrder', state.sortOrder);
  safeAdd('filterGlobal', state.filterGlobal);

  try {
    safeAdd('codigo', state.codigo);
  } catch (_) {}
  try {
    safeAdd('codigoBarra', state.codigoBarra);
  } catch (_) {}
  try {
    safeAdd('nombre', state.nombre);
  } catch (_) {}
  try {
    safeAdd('tipo', (state.tipo?.isNotEmpty ?? false) ? state.tipo : null);
  } catch (_) {}
  try {
    safeAdd('idMarca', state.idMarca);
  } catch (_) {}
  try {
    safeAdd('codigoMoneda', state.codigoMoneda);
  } catch (_) {}
  try {
    safeAdd('idCategoria', (state.idCategoria?.isNotEmpty ?? false) ? state.idCategoria : null);
  } catch (_) {}
  try {
    safeAdd('mostrarEnRestaurante', state.mostrarEnRestaurante);
  } catch (_) {}
  try {
    safeAdd('mostrarEnWeb', state.mostrarEnWeb);
  } catch (_) {}
  try {
    safeAdd('favorito', state.favorito);
  } catch (_) {}
  try {
    safeAdd('idPuntoVenta', state.idPuntoVenta);
  } catch (_) {}
  try {
    safeAdd('idPuntoVentaOrder', state.idPuntoVentaOrder);
  } catch (_) {}
  try {
    safeAdd('limit', state.limit);
  } catch (_) {}

  return params;
}
