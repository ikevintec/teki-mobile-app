import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/totales_comprobantes.dart';
import 'package:teki_app/src/data/models/teki_model/totales_forma_pagos.dart';
import 'package:teki_app/src/domain/repositories/tickets_sale_repository.dart';

class VentasPrueba implements TicketsSaleRepository {
  final consultas = <Map<String, dynamic>>[];
  final totales = <Map<String, dynamic>>[];
  final pagos = <Map<String, dynamic>>[];
  List<Ticket> filtradas(Map<String, dynamic> p) {
    final texto = '${p['filtroRuc'] ?? ''}'.toLowerCase();
    return List.generate(
          15,
          (i) => Ticket(
            id: i + 1,
            identificadorDocumento: 'qa-venta-${i + 1}',
            serie: 'F001',
            numero: i + 1,
            tipoComprobante: '01',
            fechaEmisionDate: DateTime.now(),
            codigoMoneda: 'PEN',
            totalVenta: 30,
            denominacionReceptor: i < 10 ? 'Bodega Norte' : 'Bodega Sur',
            numeroDocumentoReceptor: i < 10 ? '20123456789' : '87654321',
            tipoVenta: 'CONTADO',
          ),
        )
        .where(
          (t) => '${t.denominacionReceptor} ${t.numeroDocumentoReceptor}'
              .toLowerCase()
              .contains(texto),
        )
        .toList();
  }

  @override
  Future<List<Ticket>> getComprobantes(Map<String, dynamic> p) async {
    consultas.add(Map.of(p));
    final page = p['pageNumber'] as int? ?? 0;
    return filtradas(p).skip(page * 5).take(5).toList();
  }

  @override
  Future<List<TotalesPorMoneda>> getTotalesPorMoneda(
    Map<String, dynamic> p,
  ) async {
    totales.add(Map.of(p));
    return [
      TotalesPorMoneda.fromJson({
        'codigoMoneda': 'PEN',
        'totalFacturas': filtradas(p).length * 30,
      }),
    ];
  }

  @override
  Future<List<TotalVentasFormaPago>> getTotalesFormaPago(
    Map<String, dynamic> p,
  ) async {
    pagos.add(Map.of(p));
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
