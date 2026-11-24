import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/esc_pos/command_print.dart';
import 'package:teki_app/src/data/models/teki_model/printer.dart';
import 'package:teki_app/src/shared/services/command_esc_pos_formatter.dart';

/// Extrae los valores de texto de la salida del formatter (lista de JSON).
List<String> textValues(List<Map<String, dynamic>> orders) => orders
    .map((o) => (o['text'] as Map<String, dynamic>?)?['value'] as String?)
    .whereType<String>()
    .toList();

void main() {
  final formatter = CommandEscPosFormatter();

  CommandPrint buildComanda({
    bool? anulacion,
    String? fechaAnulacion,
    String? propina,
    String? totalConPropina,
    List<CommandItemPrint>? items,
  }) {
    return CommandPrint(
      orden: '00000123',
      fecha: '21/07/2026',
      hora: '13:45',
      camarero: 'juan perez',
      nombreCliente: 'CLIENTE VARIOS',
      mesa: 'm-01',
      salon: 'principal',
      zona: 'cocina',
      anulacion: anulacion,
      fechaAnulacion: fechaAnulacion,
      propina: propina,
      totalConPropina: totalConPropina,
      items: items ??
          [
            CommandItemPrint(
                cantidad: '2', producto: 'lomo saltado', extras: 'sin cebolla'),
            CommandItemPrint(cantidad: '1', producto: 'inca kola'),
          ],
    );
  }

  group('CommandEscPosFormatter', () {
    test('comanda básica incluye todas las secciones', () {
      final out = formatter.format(buildComanda(), Printer());
      final texts = textValues(out);

      expect(texts, contains('ORDEN 00000123'));
      expect(texts, contains('FECHA: 21/07/2026 - 13:45'));
      expect(texts, contains('JUAN PEREZ')); // camarero en mayúsculas
      expect(texts, contains('MESA: M-01'));
      expect(texts, contains('SALON: PRINCIPAL'));
      expect(texts, contains('AREA: COCINA'));
      expect(texts, contains('2 - LOMO SALTADO'));
      expect(texts, contains('SIN CEBOLLA'));
      expect(texts, contains('1 - INCA KOLA'));
      // Sin anulación ni propina
      expect(texts, isNot(contains('ANULACION')));
      expect(texts.any((t) => t.startsWith('PROPINA')), isFalse);
    });

    test('separador según ancho de papel', () {
      final out80 = formatter.format(buildComanda(), Printer(anchoPapel: 80));
      final out58 = formatter.format(buildComanda(), Printer(anchoPapel: 58));

      expect(
        textValues(out80).where((t) => t == '-' * 48).length,
        2,
        reason: 'papel de 80mm usa separador de 48 guiones',
      );
      expect(
        textValues(out58).where((t) => t == '-' * 31).length,
        2,
        reason: 'papel de 58mm usa separador de 31 guiones',
      );
    });

    test('flags ocultar* de la impresora suprimen secciones', () {
      final printer = Printer(
        ocultarNumeroOrden: true,
        ocultarFecha: true,
        ocultarCamarero: true,
        ocultarCliente: true,
        ocultarMesa: true,
        ocultarSalon: true,
        ocultarArea: true,
        ocultarItems: true,
      );
      final texts = textValues(formatter.format(buildComanda(), printer));

      expect(texts.any((t) => t.startsWith('ORDEN')), isFalse);
      expect(texts.any((t) => t.startsWith('FECHA')), isFalse);
      expect(texts.any((t) => t.startsWith('CAMARERO')), isFalse);
      expect(texts.any((t) => t.startsWith('CLIENTE')), isFalse);
      expect(texts.any((t) => t.startsWith('MESA')), isFalse);
      expect(texts.any((t) => t.startsWith('SALON')), isFalse);
      expect(texts.any((t) => t.startsWith('AREA')), isFalse);
      expect(texts.any((t) => t.contains('LOMO SALTADO')), isFalse);
    });

    test('anulación: sin fecha normal, con bloque ANULACION y motivo', () {
      final comanda = buildComanda(
        anulacion: true,
        fechaAnulacion: '22/07/2026 09:00',
        items: [
          CommandItemPrint(
            cantidad: '1',
            producto: 'ceviche',
            motivoAnulacion: 'cliente se retiró',
          ),
        ],
      );
      final texts = textValues(formatter.format(comanda, Printer()));

      expect(texts.any((t) => t.startsWith('FECHA:')), isFalse,
          reason: 'en anulación no se imprime la fecha normal');
      expect(texts, contains('FECHA ANULACION: 22/07/2026 09:00'));
      expect(texts, contains('ANULACION'));
      expect(texts, contains('Motivo anulación: cliente se retiró'));
    });

    test('propina y total con propina', () {
      final texts = textValues(formatter.format(
        buildComanda(propina: 'S/. 5.00', totalConPropina: 'S/. 55.00'),
        Printer(),
      ));

      expect(texts, contains('PROPINA: '));
      expect(texts, contains('S/. 5.00'));
      expect(texts, contains('TOTAL CON PROPINA: S/. 55.00'));
    });

    test('logo solo se imprime si la impresora lo permite', () {
      final conLogo = CommandPrint(logo: 'http://logo.png', items: const []);

      final sinPermiso = formatter.format(conLogo, Printer());
      expect(sinPermiso.any((o) => o.containsKey('image')), isFalse);

      final conPermiso =
          formatter.format(conLogo, Printer(imprimirLogoTicket: true));
      expect(conPermiso.any((o) => o.containsKey('image')), isTrue);
    });
  });
}
