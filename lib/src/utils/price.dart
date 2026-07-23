import 'package:flutter/foundation.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/product_price.dart';

double getPriceProduct(Product product, Office puntoVenta, Map<String, dynamic>? ops) {
    ops ??= {};
    if (product.preciosVenta == null || product.preciosVenta!.isEmpty) {
      return 0;
    } else {
      final listPrices = product.preciosVenta!.where((pv) =>
          (product.preciosPorPuntoVenta! &&
              pv.puntoVenta != null &&
              pv.puntoVenta!.id == puntoVenta.id) ||
          (!product.preciosPorPuntoVenta! && pv.puntoVenta == null)).toList();

      final double igv = (ops['igv'] ?? 0).toDouble();

      // Mayoreo
      if (ops.containsKey('qty')) {
        final wholesalePrice = _wholesale(listPrices, ops['qty']);
        if (wholesalePrice != null) {
          double price = wholesalePrice.precio ?? 0;
          if (!product.igv!) {
            price *= (1 + igv);
          }
          // Apply the same porcentajeRecargoPorItem adjustment as the default price
          // so the recargo is handled globally (otrosCargos) and not double-counted.
          if (ops.containsKey('porcentajeRecargoPorItem') && !(ops['absolute'] ?? false)) {
            final double porcentajeRecargo = (ops['porcentajeRecargoPorItem'] ?? 0).toDouble();
            price = (price / (1 + igv + (porcentajeRecargo / 100))) * (1 + igv);
          }
          return price;
        }
      }

      // Default
      final defaultPriceObj =
          listPrices.firstWhere((pv) => pv.tipoPrecio == 'POR_DEFECTO', orElse: () => ProductPrice(precio: 0, tipoPrecio: 'POR_DEFECTO'));
      double defaultPrice = defaultPriceObj.precio ?? 0;

      if (!product.igv!) {
        defaultPrice *= (1 + igv);
      }

      if (ops.containsKey('porcentajeRecargoPorItem') && !(ops['absolute'] ?? false)) {
        final double porcentajeRecargo = (ops['porcentajeRecargoPorItem'] ?? 0).toDouble();
        defaultPrice = (defaultPrice / (1 + igv + (porcentajeRecargo / 100))) * (1 + igv);
        debugPrint('Precio tiene recargo en el producto: $defaultPrice');
      }

      return defaultPrice;
    }
  }

  ProductPrice? _wholesale(List<ProductPrice> arr, double target) {
    // Paridad con la web (util-functions.ts wholesale): solo precios de tipo
    // MAYOREO y ORDENADOS por unidadesMayoreo — la búsqueda binaria de abajo
    // exige orden ascendente; sin él puede devolver el tramo equivocado.
    arr = arr
        .where((pv) =>
            pv.tipoPrecio == 'MAYOREO' && pv.unidadesMayoreo != null)
        .toList()
      ..sort((a, b) => a.unidadesMayoreo!.compareTo(b.unidadesMayoreo!));
    int start = 0;
    int end = arr.length - 1;
    int ans = -1;

    while (start <= end) {
      int mid = (start + end) ~/ 2;
      if (arr[mid].unidadesMayoreo! > target) {
        end = mid - 1;
      } else {
        ans = mid;
        start = mid + 1;
      }
    }

    return ans >= 0 ? arr[ans] : null;
  }