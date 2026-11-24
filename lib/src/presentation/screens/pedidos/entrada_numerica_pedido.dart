import 'package:flutter/material.dart';

/// El estado del diálogo conserva el controlador hasta desmontar la ruta,
/// incluyendo la animación de salida y los cambios de foco del teclado.
class EntradaNumericaPedido extends StatefulWidget {
  final String titulo, etiqueta, accion;
  final String? ayuda, textoInicial;
  final bool permitirCero;

  const EntradaNumericaPedido({
    super.key,
    required this.titulo,
    required this.etiqueta,
    required this.accion,
    this.ayuda,
    this.textoInicial,
    this.permitirCero = false,
  });

  @override
  State<EntradaNumericaPedido> createState() => _EntradaNumericaPedidoState();
}

class _EntradaNumericaPedidoState extends State<EntradaNumericaPedido> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _texto;

  @override
  void initState() {
    super.initState();
    final inicial = widget.textoInicial ?? '';
    // Seleccionado para que escribir reemplace el valor sin borrarlo antes.
    _texto = TextEditingController(text: inicial)
      ..selection = TextSelection(baseOffset: 0, extentOffset: inicial.length);
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  double? _numero(String? texto) =>
      double.tryParse((texto ?? '').trim().replaceAll(',', '.'));

  void _aplicar() {
    if (_form.currentState!.validate()) {
      Navigator.pop(context, _numero(_texto.text));
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.titulo),
    content: Form(
      key: _form,
      child: TextFormField(
        controller: _texto,
        autofocus: true,
        autocorrect: false,
        enableSuggestions: false,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _aplicar(),
        decoration: InputDecoration(
          labelText: widget.etiqueta,
          helperText: widget.ayuda,
          helperMaxLines: 3,
          errorMaxLines: 3,
        ),
        validator: (texto) {
          final n = _numero(texto);
          if (n == null || !n.isFinite) return 'Ingresa un número válido.';
          if (widget.permitirCero ? n < 0 : n <= 0) {
            return widget.permitirCero
                ? 'El precio no puede ser negativo.'
                : 'La cantidad debe ser mayor a cero.';
          }
          return null;
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      TextButton(onPressed: _aplicar, child: Text(widget.accion)),
    ],
  );
}
