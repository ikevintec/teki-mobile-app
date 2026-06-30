class CommandItemPrint {
  final String? producto;
  final String? extras;
  final String? cantidad;
  final String? motivoAnulacion;

  CommandItemPrint({this.producto, this.extras, this.cantidad, this.motivoAnulacion});

  factory CommandItemPrint.fromJson(Map<String, dynamic> json) => CommandItemPrint(
        producto: json['producto']?.toString(),
        extras: json['extras']?.toString(),
        cantidad: json['cantidad']?.toString(),
        motivoAnulacion: json['motivoAnulacion']?.toString(),
      );
}

class CommandPrint {
  final String? logo;
  final String? orden;
  final String? zona;
  final String? fecha;
  final String? fechaAnulacion;
  final String? hora;
  final String? salon;
  final String? camarero;
  final String? nombreCliente;
  final String? mesa;
  final String? propina;
  final String? totalConPropina;
  final List<CommandItemPrint>? items;
  final bool? anulacion;

  CommandPrint({
    this.logo,
    this.orden,
    this.zona,
    this.fecha,
    this.fechaAnulacion,
    this.hora,
    this.salon,
    this.camarero,
    this.nombreCliente,
    this.mesa,
    this.propina,
    this.totalConPropina,
    this.items,
    this.anulacion,
  });

  factory CommandPrint.fromJson(Map<String, dynamic> json) => CommandPrint(
        logo: json['logo']?.toString(),
        orden: json['orden']?.toString(),
        zona: json['zona']?.toString(),
        fecha: json['fecha']?.toString(),
        fechaAnulacion: json['fechaAnulacion']?.toString(),
        hora: json['hora']?.toString(),
        salon: json['salon']?.toString(),
        camarero: json['camarero']?.toString(),
        nombreCliente: json['nombreCliente']?.toString(),
        mesa: json['mesa']?.toString(),
        propina: json['propina']?.toString(),
        totalConPropina: json['totalConPropina']?.toString(),
        items: (json['items'] as List?)
            ?.map((e) => CommandItemPrint.fromJson(e as Map<String, dynamic>))
            .toList(),
        anulacion: json['anulacion'] as bool?,
      );
}
