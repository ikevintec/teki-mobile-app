import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/product_price.dart';

/// Contexto acotado a empresa/sede/usuario; nunca es una autorización de escritura.
class ContextoComercial {
  final bool promocionesDisponibles;
  final bool activo;
  final bool mayoreoManual;
  final int? cabecera;
  final List<Map<String, dynamic>> tipos;
  const ContextoComercial({
    this.promocionesDisponibles = true,
    this.activo = false,
    this.mayoreoManual = false,
    this.cabecera,
    this.tipos = const [],
  });

  ContextoComercial conCabecera(int? id) => ContextoComercial(
    activo: activo,
    promocionesDisponibles: promocionesDisponibles,
    mayoreoManual: mayoreoManual,
    cabecera: id,
    tipos: tipos,
  );

  List<ProductPrice> precios(Product p, int? sede) => (p.preciosVenta ?? [])
      .where(
        (precio) =>
            precio.estado != false &&
            precio.eliminado != true &&
            precio.paraCanje != true,
      )
      .where(
        (precio) => activo
            ? tipos.any(
                    (t) =>
                        t['id'] == precio.tipoComercialId &&
                        t['estado'] != false &&
                        (t['idPuntoVenta'] == null ||
                            t['idPuntoVenta'] == sede),
                  ) &&
                  (precio.puntoVenta == null || precio.puntoVenta?.id == sede)
            : precio.tipoComercialId == null &&
                  ((p.preciosPorPuntoVenta ?? false)
                      ? precio.puntoVenta?.id == sede
                      : precio.puntoVenta == null),
      )
      .toList();

  ProductPrice? elegir(
    Product p,
    int? sede,
    double cantidad, {
    int? tipo,
    bool explicito = false,
  }) {
    final lista = precios(p, sede);
    if (!activo) return null;
    final elegido = tipo ?? cabecera;
    final minorista = tipos
        .where((t) => t['principal'] == true && t['estado'] != false)
        .firstOrNull;
    var candidatos = lista.where((p) => p.tipoComercialId == elegido).toList();
    final categoria = tipos
        .where((t) => t['id'] == elegido)
        .firstOrNull?['categoria'];
    if (!mayoreoManual && !explicito && categoria == 'POR_DEFECTO') {
      final mayores =
          lista
              .where(
                (p) =>
                    p.tipoPrecio == 'MAYOREO' &&
                    (p.unidadesMayoreo ?? 0) > 0 &&
                    p.unidadesMayoreo! <= cantidad,
              )
              .toList()
            ..sort((a, b) => b.unidadesMayoreo!.compareTo(a.unidadesMayoreo!));
      if (mayores.isNotEmpty) return mayores.first;
    }
    if (candidatos.isEmpty) {
      candidatos = lista
          .where((p) => p.tipoComercialId == minorista?['id'])
          .toList();
    }
    candidatos.sort(
      (a, b) => (b.puntoVenta?.id == sede ? 1 : 0).compareTo(
        a.puntoVenta?.id == sede ? 1 : 0,
      ),
    );
    return candidatos.firstOrNull;
  }

  Map<String, dynamic>? tipo(int? id) =>
      tipos.where((t) => t['id'] == id).firstOrNull;
}
