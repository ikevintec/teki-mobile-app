import 'package:reactive_forms/reactive_forms.dart';
import 'package:teki_app/src/utils/price_formatter.dart';

/// ValueAccessor que formatea precios de forma inteligente
/// Muestra enteros sin decimales y conserva decimales cuando es necesario
class SmartPriceValueAccessor extends ControlValueAccessor<double, String> {
  @override
  String? modelToViewValue(double? modelValue) {
    return PriceFormatter.formatPrice(modelValue);
  }

  @override
  double? viewToModelValue(String? viewValue) {
    return PriceFormatter.parsePrice(viewValue);
  }
}