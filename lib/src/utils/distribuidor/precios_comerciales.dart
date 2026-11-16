import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/product_price.dart';

class PrecioComercialResuelto {
  final ProductPrice? precio;
  final Map<String, dynamic>? tipo;
  final String? aviso;
  const PrecioComercialResuelto(this.precio, this.tipo, this.aviso);
  Map<String, dynamic> get atribucion => {
    'tipoComercialId': tipo?['id'],
    'tipoComercialCategoria': tipo?['categoria'],
    'tipoComercialNombre': tipo?['nombre'],
    'productoPrecioId': precio?.id,
    'origenPrecio': precio == null ? 'MANUAL' : 'AUTOMATICO',
  };
}

/// Respuesta inmediata para la pantalla; el backend valida la misma selección al guardar.
PrecioComercialResuelto resolverPrecioComercial(
  Product producto,
  List<Map<String, dynamic>> tipos,
  int? sede,
  int? solicitado,
  double cantidad,
  bool mayoreoManual,
) {
  final elegibles = tipos
      .where(
        (t) =>
            t['estado'] == true &&
            (t['idPuntoVenta'] == null || t['idPuntoVenta'] == sede),
      )
      .toList();
  Map<String, dynamic>? tipo(int? id) {
    for (final t in elegibles) {
      if (t['id'] == id) return t;
    }
    return null;
  }

  Map<String, dynamic>? principal;
  for (final t in elegibles) {
    if (t['principal'] == true && t['categoria'] == 'POR_DEFECTO') {
      principal = t;
      break;
    }
  }
  final pedido = tipo(solicitado) ?? principal;
  final precios = (producto.preciosVenta ?? [])
      .where(
        (p) =>
            p.paraCanje != true &&
            tipo(p.tipoComercialId) != null &&
            (p.puntoVenta == null || p.puntoVenta?.id == sede),
      )
      .toList();
  ProductPrice? deTipo(int? id) {
    final opciones = precios.where((p) => p.tipoComercialId == id).toList()
      ..sort((a, b) {
        final sede = (b.puntoVenta == null ? 0 : 1).compareTo(
          a.puntoVenta == null ? 0 : 1,
        );
        return sede != 0 ? sede : (a.id ?? 0).compareTo(b.id ?? 0);
      });
    return opciones.isEmpty ? null : opciones.first;
  }

  ProductPrice? elegido;
  if (!mayoreoManual &&
      (pedido == null || pedido['categoria'] == 'POR_DEFECTO')) {
    final escalas =
        precios
            .where(
              (p) =>
                  tipo(p.tipoComercialId)?['categoria'] == 'MAYOREO' &&
                  (p.unidadesMayoreo ?? 0) > 0 &&
                  cantidad >= p.unidadesMayoreo!,
            )
            .toList()
          ..sort((a, b) {
            final escala = b.unidadesMayoreo!.compareTo(a.unidadesMayoreo!);
            if (escala != 0) return escala;
            final sede = (b.puntoVenta == null ? 0 : 1).compareTo(
              a.puntoVenta == null ? 0 : 1,
            );
            return sede != 0 ? sede : (a.id ?? 0).compareTo(b.id ?? 0);
          });
    if (escalas.isNotEmpty) elegido = escalas.first;
  }
  elegido ??= deTipo(pedido?['id']);
  final falta = elegido == null;
  elegido ??= deTipo(principal?['id']);
  return PrecioComercialResuelto(
    elegido,
    tipo(elegido?.tipoComercialId) ?? principal,
    elegido == null
        ? 'Sin precio configurado. Ingresa un importe autorizado.'
        : falta && pedido?['id'] != principal?['id']
        ? 'Sin precio ${pedido?['nombre']}; se aplicó ${principal?['nombre']}.'
        : null,
  );
}
