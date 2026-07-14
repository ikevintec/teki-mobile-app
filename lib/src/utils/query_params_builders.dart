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
    safeAdd('idCategoria',
        (state.idCategoria?.isNotEmpty ?? false) ? state.idCategoria : null);
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

/// Params para la búsqueda ligera de productos (endpoint `/products/search`).
/// A diferencia de [buildProductQueryParams], este devuelve una lista plana
/// (sin paginación) con la data mínima necesaria del producto. El detalle
/// completo se obtiene aparte al seleccionar el producto (`/products/{id}`).
Map<String, dynamic> buildProductSearchQueryParams(dynamic state) {
  final Map<String, dynamic> params = {
    'paginacion': false,
    'limit': 50,
    'sortField': 'createdOn',
    'sortOrder': -1,
  };

  void safeAdd(String key, dynamic value) {
    if (value != null) params[key] = value;
  }

  safeAdd('filterGlobal', state.filterGlobal);

  return params;
}

Map<String, dynamic> buildComprobanteQueryParams(dynamic state) {
  final Map<String, dynamic> params = {};

  void safeAdd(String key, dynamic value) {
    if (value != null) params[key] = value;
  }

  safeAdd('pageNumber', state.pageNumber);
  safeAdd('perPage', state.perPage);

  try {
    // Solo se filtra por vendedor si hay uno seleccionado (0 = todos)
    if (state.idVendedor != null && state.idVendedor > 0) {
      safeAdd('idVendedor', state.idVendedor);
    }
  } catch (_) {}
  try {
    safeAdd('filtroDesde', state.filtroDesde);
  } catch (_) {}

  try {
    safeAdd('filtroHasta', state.filtroHasta);
  } catch (_) {}

  try {
    safeAdd('idPuntoVenta', state.idPuntoVenta);
  } catch (_) {}
  try {
    safeAdd('filtroRucEmisor', state.filtroRucEmisor);
  } catch (_) {}
  try {
    safeAdd('filtroCanal', state.filtroCanal);
  } catch (_) {
    safeAdd('filtroCanal', 'PLATFORM');
  }
  try {
    safeAdd('sortOrder', state.sortOrder);
  } catch (_) {
    safeAdd('sortOrder', '1');
  }

  // Nuevos filtros adicionales
  try {
    safeAdd('filtroSerie', state.filtroSerie);
  } catch (_) {}
  try {
    safeAdd('filtroNumero', state.filtroNumero);
  } catch (_) {}
  try {
    // Para filtros múltiples como filtroTipoComprobante, se agregan múltiples parámetros
    if (state.filtroTipoComprobante != null &&
        state.filtroTipoComprobante.isNotEmpty) {
      for (String tipo in state.filtroTipoComprobante) {
        if (!params.containsKey('filtroTipoComprobante')) {
          params['filtroTipoComprobante'] = [];
        }
        params['filtroTipoComprobante'].add(tipo);
      }
    }
  } catch (_) {}
  try {
    // Para filtros múltiples como idMetodoPago, se agregan múltiples parámetros
    if (state.idMetodoPago != null && state.idMetodoPago.isNotEmpty) {
      for (String metodo in state.idMetodoPago) {
        if (!params.containsKey('idMetodoPago')) {
          params['idMetodoPago'] = [];
        }
        params['idMetodoPago'].add(metodo);
      }
    }
  } catch (_) {}
  try {
    // Convertir filtroEstado string a filtroEstadoAnulacion booleano
    if (state.filtroEstado != null &&
        state.filtroEstado.toLowerCase() != 'todos') {
      if (state.filtroEstado.toLowerCase() == 'activos') {
        safeAdd('filtroEstadoAnulacion', false); // false = NO anulado = activo
      } else if (state.filtroEstado.toLowerCase() == 'anulados') {
        safeAdd('filtroEstadoAnulacion', true); // true = anulado
      }
    }
    // Si es "Todos" o null, no agregar el parámetro
  } catch (_) {}

  return params;
}

Map<String, dynamic> buildQuotationQueryParams(dynamic state) {
  final Map<String, dynamic> params = {};

  void safeAdd(String key, dynamic value) {
    if (value != null) params[key] = value;
  }

  safeAdd('esPedido', 0);
  safeAdd('pageNumber', state.pageNumber);
  safeAdd('perPage', state.perPage);
  safeAdd('sortOrder', state.sortOrder);

  try {
    safeAdd('filtroDesde', state.filtroDesde);
  } catch (_) {}
  try {
    safeAdd('filtroHasta', state.filtroHasta);
  } catch (_) {}
  try {
    safeAdd('filtroRucEmisor', state.filtroRucEmisor);
  } catch (_) {}
  try {
    safeAdd('idPuntoVenta', state.idPuntoVenta);
  } catch (_) {}
  try {
    safeAdd('idVendedor', state.idVendedor);
  } catch (_) {}
  try {
    safeAdd('filtroSerie', state.filtroSerie);
  } catch (_) {}
  try {
    safeAdd('filtroNumero', state.filtroNumero);
  } catch (_) {}
  try {
    if (state.filtroEstadoCotizacion != null &&
        state.filtroEstadoCotizacion.toString().toLowerCase() != 'todos') {
      safeAdd('estadoCotizacion', state.filtroEstadoCotizacion);
    }
  } catch (_) {}

  return params;
}

Map<String, dynamic> buildOrdersRestaurantQueryParams(dynamic state) {
  final Map<String, dynamic> params = {};

  void safeAdd(String key, dynamic value) {
    if (value != null) params[key] = value;
  }

  safeAdd('idPuntoVenta', state.idPuntoVenta);
  safeAdd('pageNumber', state.pageNumber);
  safeAdd('perPage', state.perPage);
  params['borradores'] = false;
  safeAdd('sortField', state.sortField);
  safeAdd('sortOrder', state.sortOrder);
  safeAdd('desde', state.desde);
  safeAdd('hasta', state.hasta);

  try {
    if (state.nombreCliente != null &&
        (state.nombreCliente as String).isNotEmpty) {
      safeAdd('nombreCliente', state.nombreCliente);
    }
  } catch (_) {}

  try {
    if (state.pedidoFacturado != null) {
      safeAdd('pedidoFacturado', state.pedidoFacturado);
    }
  } catch (_) {}

  try {
    if (state.tipos != null && (state.tipos as List).isNotEmpty) {
      params['tipo'] = state.tipos;
    }
  } catch (_) {}

  try {
    if (state.estados != null && (state.estados as List).isNotEmpty) {
      params['estado'] = state.estados;
    }
  } catch (_) {}

  return params;
}

Map<String, dynamic> buildInventoryQueryParams(dynamic state) {
  final Map<String, dynamic> params = {};

  void safeAdd(String key, dynamic value) {
    if (value != null) params[key] = value;
  }

  safeAdd('pageNumber', state.pageNumber);
  safeAdd('paginacion', true);
  safeAdd('perPage', state.perPage);
  safeAdd('sortField', state.sortField);
  safeAdd('sortOrder', state.sortOrder);
  safeAdd('idPuntoVenta', state.idPuntoVenta);
  try {
    if (state.filterGlobal != null &&
        (state.filterGlobal as String).isNotEmpty) {
      safeAdd('clave', state.filterGlobal);
    }
  } catch (_) {}

  return params;
}

Map<String, dynamic> buildInventoryLogsQueryParams(dynamic state) {
  final Map<String, dynamic> params = {};

  void safeAdd(String key, dynamic value) {
    if (value != null) params[key] = value;
  }

  safeAdd('pageNumber', state.pageNumber);
  safeAdd('paginacion', true);
  safeAdd('perPage', state.perPage);
  safeAdd('sortField', 'fecha');
  safeAdd('sortOrder', -1); // más reciente primero

  return params;
}

Map<String, dynamic> buildCustomersQueryParams(dynamic state) {
  final Map<String, dynamic> params = {};

  void safeAdd(String key, dynamic value) {
    if (value != null) params[key] = value;
  }

  safeAdd('pageNumber', state.pageNumber);
  safeAdd('paginacion', state.paginacion);
  safeAdd('perPage', state.perPage);
  safeAdd('sortField', state.sortField);
  safeAdd('sortOrder', state.sortOrder);
  try {
    safeAdd('filtro', state.filtro);
  } catch (_) {}
  try {
    safeAdd('telefono', state.telefono);
  } catch (_) {}
  try {
    safeAdd('email', state.email);
  } catch (_) {}

  return params;
}

Map<String, dynamic> buildAccountsReceivableQueryParams(dynamic state) {
  final Map<String, dynamic> params = {};

  void safeAdd(String key, dynamic value) {
    if (value != null) params[key] = value;
  }

  safeAdd('tipoCuenta', state.tipoCuenta);
  safeAdd('pageNumber', state.pageNumber);
  safeAdd('perPage', state.perPage);
  safeAdd('sortOrder', 1);

  // idPuntoVenta: null significa "Todos" -> no se envía el parámetro
  try {
    safeAdd('idPuntoVenta', state.idPuntoVenta);
  } catch (_) {}

  try {
    safeAdd('idVendedor', state.idVendedor);
  } catch (_) {}

  try {
    safeAdd('filtroEmisionDesde', state.filtroEmisionDesde);
  } catch (_) {}
  try {
    safeAdd('filtroEmisionHasta', state.filtroEmisionHasta);
  } catch (_) {}
  try {
    safeAdd('filtroVencimientoDesde', state.filtroVencimientoDesde);
  } catch (_) {}
  try {
    safeAdd('filtroVencimientoHasta', state.filtroVencimientoHasta);
  } catch (_) {}

  try {
    if (state.tipoComprobante != null && state.tipoComprobante.isNotEmpty) {
      params['tipoComprobante'] = state.tipoComprobante;
    }
  } catch (_) {}

  try {
    if (state.estadoCredito != null && state.estadoCredito.isNotEmpty) {
      params['estadoCredito'] = state.estadoCredito;
    }
  } catch (_) {}

  try {
    final diasCredito = state.diasCredito;
    if (diasCredito != null && diasCredito.toString().trim().isNotEmpty) {
      final parsed = int.tryParse(diasCredito.toString().trim());
      if (parsed != null) params['diasCredito'] = parsed;
    }
  } catch (_) {}

  // Campos específicos por tipo de cuenta
  try {
    if (state.tipoCuenta == 'CC') {
      safeAdd('serie', state.serie);
      safeAdd('numero', state.numero);
    } else {
      safeAdd('comprobante', state.comprobante);
    }
  } catch (_) {}
  try {
    safeAdd('cliente', state.cliente);
  } catch (_) {}

  return params;
}
