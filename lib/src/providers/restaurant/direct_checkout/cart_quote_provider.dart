import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/order_restaurant.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/restaurant/comanda_provider.dart';
import 'direct_checkout_service.dart';

OrderRestaurant directOrderFromCart(List<CartItem> cart, Office? office) =>
    OrderRestaurant(
      puntoVenta: office,
      tipo: 'PEDIDO_LOCAL_INTERNO',
      montoDelivery: 0,
      comandas: [
        Command(
          items: cart
              .map(
                (item) => CommandDetail(
                  producto: item.product,
                  cantidad: item.quantity.toDouble(),
                  precioVenta: item.unitTotal,
                  nota: item.nota,
                  paraLlevar: item.paraLlevar,
                  grupoProductoOpciones: item.grupoOpciones,
                  preparacionProductoOpciones: item.preparacionOpciones,
                ),
              )
              .toList(),
        ),
      ],
    );

/// Dependency changes discard obsolete results. Failed previews remain estimates
/// and cannot prevent drafting or opening the full editor.
final restaurantCartQuoteProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
      final cart = ref.watch(comandaProvider.select((s) => s.cartItems));
      final context = ref.watch(
        comandaProvider.select((s) => (s.table, s.existingOrderId)),
      );
      final session = ref.watch(sesionProvider);
      if (context.$1 != null ||
          context.$2 != null ||
          cart.isEmpty ||
          session.office?.id == null ||
          session.saleStation?.id == null) {
        return null;
      }
      final service = ref.watch(directCheckoutServiceProvider);
      var active = true;
      ref.onDispose(() => active = false);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!active) return null;
      return service.preview({
        'pedido': directOrderFromCart(cart, session.office).toJson(),
        'idEstacionVenta': session.saleStation!.id,
        'tipoComprobante': session.config?.tipoComprobantePorDefecto ?? 'NV',
        'excluirIgv': false,
      });
    });
