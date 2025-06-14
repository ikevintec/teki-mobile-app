import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';

class QuantitySelectorWidget extends StatefulWidget {
  final int initialValue;
  final ValueChanged<int> onChanged;
  final List<String? Function(int)>? validators;

  const QuantitySelectorWidget({
    super.key,
    this.initialValue = 1,
    required this.onChanged,
    this.validators,
  });

  @override
  State<QuantitySelectorWidget> createState() => _QuantitySelectorWidgetState();
}

class _QuantitySelectorWidgetState extends State<QuantitySelectorWidget> {
  late int _quantity;
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialValue;
    _controller.text = _quantity.toString();
  }

  void _updateQuantity(int newQuantity) {
    final error = _validate(newQuantity);
    if (error != null) {
      setState(() {
        _errorText = error;
      });
      return;
    }
    setState(() {
      _quantity = newQuantity;
      _controller.text = _quantity.toString();
      _errorText = null;
    });
    widget.onChanged(_quantity);
  }

  void _increment() {
    final currentQuantity = int.tryParse(_controller.text) ?? _quantity;
    _updateQuantity(currentQuantity + 1);
  }

  void _decrement() {
    final currentQuantity = int.tryParse(_controller.text) ?? _quantity;
    if (currentQuantity > 1) {
      _updateQuantity(currentQuantity - 1);
    }
  }

  void _onTextChanged(String value) {
    final parsed = int.tryParse(value);
    if (parsed != null) {
      _updateQuantity(parsed);
    }
  }

  String? _validate(int value) {
    if (widget.validators == null) return null;
    for (final validator in widget.validators!) {
      final result = validator(value);
      if (result != null) return result;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          onPressed: _decrement,
          icon: const Icon(Icons.remove, size: 15),
        ),
        SizedBox(
          width: 40,
          height: 30,
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              border: InputBorder.none,
              errorText: _errorText,
            ),
            onChanged: _onTextChanged,
          ),
        ),
        IconButton(
          onPressed: _increment,
          icon: const Icon(Icons.add, size: 15),
        ),
      ],
    );
  }
}



class ReactiveQuantitySelector extends StatelessWidget {
  final String formControlName;
  final Function(FormControl<int>)? onChanged;

  const ReactiveQuantitySelector({
    super.key,
    required this.formControlName,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ReactiveValueListenableBuilder<int>(
      formControlName: formControlName,
      builder: (context, control, child) {
        int currentValue = control.value ?? 1;

        void _updateQuantity(int newQuantity) {
          control.updateValue(newQuantity);
          control.markAsTouched();
            if (onChanged != null && control is FormControl<int>) {
              onChanged!(control);
            }
        }

        void _increment() {
          _updateQuantity(currentValue + 1);
        }

        void _decrement() {
          if (currentValue > 1) {
            _updateQuantity(currentValue - 1);
          }
        }

        return Column(
          children: [
            IconButton(
              onPressed: _decrement,
              icon: const Icon(Icons.remove, size: 15),
            ),
            SizedBox(
              width: 40,
              height: 30,
              child: ReactiveTextField<int>(
                formControlName: formControlName,
                keyboardType: TextInputType.numberWithOptions(decimal: false),
                onChanged: onChanged,
                validationMessages: {
                  ValidationMessage.required: (error) => 'Cantidad requerida',
                  ValidationMessage.min: (error) => 'Debe ser al menos 1',
                },
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              onPressed: _increment,
              icon: const Icon(Icons.add, size: 15),
            ),
          ],
        );
      },
    );
  }
}
