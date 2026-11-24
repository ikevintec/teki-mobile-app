import 'package:intl/intl.dart';

/// Contrato del listado remoto; no filtra únicamente la página visible.
class FiltrosPedidos {
  final String cliente, serie;
  final String? estado;
  final int? numero;
  final DateTime? desde, hasta;
  final bool recientesPrimero;

  const FiltrosPedidos({
    this.cliente = '',
    this.serie = '',
    this.estado,
    this.numero,
    this.desde,
    this.hasta,
    this.recientesPrimero = true,
  });

  int get cantidad => [
    cliente.isNotEmpty,
    serie.isNotEmpty,
    estado != null,
    numero != null,
    desde != null && hasta != null,
    !recientesPrimero,
  ].where((activo) => activo).length;

  FiltrosPedidos conCliente(String valor) => FiltrosPedidos(
    cliente: valor.trim(),
    serie: serie,
    estado: estado,
    numero: numero,
    desde: desde,
    hasta: hasta,
    recientesPrimero: recientesPrimero,
  );

  Map<String, dynamic> get parametros => {
    if (cliente.isNotEmpty) 'filtroRuc': cliente,
    if (serie.isNotEmpty) 'filtroSerie': serie,
    if (numero != null) 'filtroNumero': numero,
    if (estado != null) 'estadoCotizacion': estado,
    if (desde != null && hasta != null) ...{
      'filtroDesde': DateFormat('dd-MM-yyyy').format(desde!),
      'filtroHasta': DateFormat('dd-MM-yyyy').format(hasta!),
    },
    'sortField': 'id',
    'sortOrder': recientesPrimero ? -1 : 1,
  };
}
