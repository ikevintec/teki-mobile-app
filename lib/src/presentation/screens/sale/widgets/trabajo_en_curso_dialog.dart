import 'package:flutter/material.dart';
import 'package:teki_app/src/utils/constants.dart';

/// Qué hacer con una venta o cotización sin terminar antes de empezar otra.
enum DecisionEnCurso { retomar, descartar }

/// Describe lo que está en curso para el aviso ("una venta", "la edición de la cotización"...).
String describirEnCurso({required bool esCotizacion, required bool esEdicion}) {
  final doc = esCotizacion ? 'cotización' : 'venta';
  return esEdicion ? 'la edición de la $doc' : 'una $doc';
}

/// Pregunta antes de descartar trabajo en curso: nunca se pierde sin avisar.
/// Devuelve null si el usuario cierra el aviso sin elegir.
Future<DecisionEnCurso?> preguntarTrabajoEnCurso(
  BuildContext context, {
  required String enCurso,
  required int productos,
  required String nuevo,
}) {
  final detalle = productos > 0
      ? ' con $productos producto${productos == 1 ? '' : 's'}'
      : '';
  return showDialog<DecisionEnCurso>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Tienes trabajo sin terminar',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
      ),
      content: Text(
        'Tienes $enCurso$detalle. Si empiezas $nuevo, se descartará.',
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
          onPressed: () => Navigator.of(ctx).pop(DecisionEnCurso.descartar),
          child: const Text('Descartar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorSchema.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => Navigator.of(ctx).pop(DecisionEnCurso.retomar),
          child: const Text('Retomar'),
        ),
      ],
    ),
  );
}
