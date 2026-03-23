class TicketFormaPago {
  final String? nombre;
  final String? monto;

  TicketFormaPago({this.nombre, this.monto});

  factory TicketFormaPago.fromJson(Map<String, dynamic> json) => TicketFormaPago(
        nombre: json['nombre']?.toString(),
        monto: json['monto']?.toString(),
      );
}

class CampoAdicional {
  final String? nombreCampo;
  final String? valorCampo;

  CampoAdicional({this.nombreCampo, this.valorCampo});

  factory CampoAdicional.fromJson(Map<String, dynamic> json) => CampoAdicional(
        nombreCampo: json['nombreCampo']?.toString(),
        valorCampo: json['valorCampo']?.toString(),
      );
}

class TicketItemPrint {
  final String? descripcion;
  final String? cantidad;
  final String? precioUnitario;
  final String? total;

  TicketItemPrint({this.descripcion, this.cantidad, this.precioUnitario, this.total});

  factory TicketItemPrint.fromJson(Map<String, dynamic> json) => TicketItemPrint(
        descripcion: json['descripcion']?.toString(),
        cantidad: json['cantidad']?.toString(),
        precioUnitario: json['precioUnitario']?.toString(),
        total: json['total']?.toString(),
      );
}

class TicketPrint {
  final String? razonSocial;
  final String? nombreComercial;
  final String? rucEmisor;
  final String? direccionEmisor;
  final String? telefonoEmisor;
  final String? emailEmisor;
  final String? tipoComprobante;
  final String? nombreComprobante;
  final String? serieCorrelativo;
  final String? nombreComprobanteAfectado;
  final String? serieAfectado;
  final String? numeroAfectado;
  final String? fechaEmision;
  final String? codigoMoneda;
  final String? monedaSimbolo;
  final String? vendedor;
  final String? montoLetras;
  final String? gratuita;
  final String? exonerada;
  final String? inafecta;
  final String? gravada;
  final String? igv;
  final String? isc;
  final String? otrosCargos;
  final String? tributosBolsas;
  final String? descuento;
  final String? totalVenta;
  final String? motivoNota;
  final String? tipoVenta;
  final String? cambio;
  final String? efectivo;
  final String? propina;
  final String? totalConPropina;
  final String? qr;
  final String? logo;
  final String? observaciones;
  final String? tipoDocumentoReceptor;
  final String? numeroDocumentoReceptor;
  final String? denominacionReceptor;
  final String? direccionReceptor;
  final String? urlConsultaComprobante;
  final List<TicketItemPrint>? items;
  final List<CampoAdicional>? adicionales;
  final List<TicketFormaPago>? formasPago;

  TicketPrint({
    this.razonSocial,
    this.nombreComercial,
    this.rucEmisor,
    this.direccionEmisor,
    this.telefonoEmisor,
    this.emailEmisor,
    this.tipoComprobante,
    this.nombreComprobante,
    this.serieCorrelativo,
    this.nombreComprobanteAfectado,
    this.serieAfectado,
    this.numeroAfectado,
    this.fechaEmision,
    this.codigoMoneda,
    this.monedaSimbolo,
    this.vendedor,
    this.montoLetras,
    this.gratuita,
    this.exonerada,
    this.inafecta,
    this.gravada,
    this.igv,
    this.isc,
    this.otrosCargos,
    this.tributosBolsas,
    this.descuento,
    this.totalVenta,
    this.motivoNota,
    this.tipoVenta,
    this.cambio,
    this.efectivo,
    this.propina,
    this.totalConPropina,
    this.qr,
    this.logo,
    this.observaciones,
    this.tipoDocumentoReceptor,
    this.numeroDocumentoReceptor,
    this.denominacionReceptor,
    this.direccionReceptor,
    this.urlConsultaComprobante,
    this.items,
    this.adicionales,
    this.formasPago,
  });

  factory TicketPrint.fromJson(Map<String, dynamic> json) => TicketPrint(
        razonSocial: json['razonSocial']?.toString(),
        nombreComercial: json['nombreComercial']?.toString(),
        rucEmisor: json['rucEmisor']?.toString(),
        direccionEmisor: json['direccionEmisor']?.toString(),
        telefonoEmisor: json['telefonoEmisor']?.toString(),
        emailEmisor: json['emailEmisor']?.toString(),
        tipoComprobante: json['tipoComprobante']?.toString(),
        nombreComprobante: json['nombreComprobante']?.toString(),
        serieCorrelativo: json['serieCorrelativo']?.toString(),
        nombreComprobanteAfectado: json['nombreComprobanteAfectado']?.toString(),
        serieAfectado: json['serieAfectado']?.toString(),
        numeroAfectado: json['numeroAfectado']?.toString(),
        fechaEmision: json['fechaEmision']?.toString(),
        codigoMoneda: json['codigoMoneda']?.toString(),
        monedaSimbolo: json['monedaSimbolo']?.toString(),
        vendedor: json['vendedor']?.toString(),
        montoLetras: json['montoLetras']?.toString(),
        gratuita: json['gratuita']?.toString(),
        exonerada: json['exonerada']?.toString(),
        inafecta: json['inafecta']?.toString(),
        gravada: json['gravada']?.toString(),
        igv: json['igv']?.toString(),
        isc: json['isc']?.toString(),
        otrosCargos: json['otrosCargos']?.toString(),
        tributosBolsas: json['tributosBolsas']?.toString(),
        descuento: json['descuento']?.toString(),
        totalVenta: json['totalVenta']?.toString(),
        motivoNota: json['motivoNota']?.toString(),
        tipoVenta: json['tipoVenta']?.toString(),
        cambio: json['cambio']?.toString(),
        efectivo: json['efectivo']?.toString(),
        propina: json['propina']?.toString(),
        totalConPropina: json['totalConPropina']?.toString(),
        qr: json['qr']?.toString(),
        logo: json['logo']?.toString(),
        observaciones: json['observaciones']?.toString(),
        tipoDocumentoReceptor: json['tipoDocumentoReceptor']?.toString(),
        numeroDocumentoReceptor: json['numeroDocumentoReceptor']?.toString(),
        denominacionReceptor: json['denominacionReceptor']?.toString(),
        direccionReceptor: json['direccionReceptor']?.toString(),
        urlConsultaComprobante: json['urlConsultaComprobante']?.toString(),
        items: (json['items'] as List?)
            ?.map((e) => TicketItemPrint.fromJson(e as Map<String, dynamic>))
            .toList(),
        adicionales: (json['adicionales'] as List?)
            ?.map((e) => CampoAdicional.fromJson(e as Map<String, dynamic>))
            .toList(),
        formasPago: (json['formasPago'] as List?)
            ?.map((e) => TicketFormaPago.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
