import 'package:teki_app/src/data/models/teki_model/command_detail.dart';
import 'package:teki_app/src/presentation/screens/restaurant/widgets/comanda_detail_item_tile.dart';

/// Cálculo del total de una cuenta/lista de items de restaurante, con las
/// mismas reglas que la web (detalle-item-cuenta): excluye los items
/// CANCELADO. `precioVenta` ya incluye los adicionales (unitTotal).
double checkItemsTotal(List<CommandDetail>? items) {
  if (items == null) return 0;
  return items
      .where((d) => !ComandaDetailStatus.isCancelledItem(d))
      .fold<double>(
        0,
        (sum, d) => sum + ((d.precioVenta ?? 0) * (d.cantidad ?? 1)),
      );
}
