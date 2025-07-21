import 'package:teki_app/src/data/models/teki_model/attachedCompany.dart';
import 'package:teki_app/src/data/models/teki_model/check.dart';
import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/company.dart';
import 'package:teki_app/src/data/models/teki_model/cutomer.dart';
import 'package:teki_app/src/data/models/teki_model/delivery.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/table.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/utils/formats.dart';

class OrderRestaurant {
  final int? id;
  final DateTime? fecha;
  final DateTime? fechaCancelacion;
  final DateTime? fechaRechazo;
  final DateTime? fechaAceptacion;
  final DateTime? fechaEnvio;
  final DateTime? fechaEntrega;
  final String? motivoRechazo;
  final String? tipo;
  final String? estado;
  final String? estadoOnline;
  final bool? confirmado;
  final String? tipoDocumentoOnline;
  final String? numeroDocumentoOnline;
  final Delivery? envio;
  final int? tiempoEntrega;
  final int? numeroOrden;
  final int? numeroComensales;
  final double? montoDelivery;
  final List<Command>? comandas;
  final List<Check>? cuentas;
  final String? tipoDocumentoReceptor;
  final String? numeroDocumentoReceptor;
  final String? denominacionReceptor;
  final String? direccionReceptor;
  final String? emailReceptor;
  final String? telefonoReceptor;
  final Customer? cliente;
  final String? nombreCliente;
  final User? usuario;
  final Table? mesa;
  final Company? empresa;
  final AttachedCompany? empresaAdjunta;
  final Office? puntoVenta;
  final String? tipoDireccion;
  final String? formaPago;
  final String? nombreFormaPago;
  final bool? requiereConfirmacionPago;
  final String? direccionCompleta;
  final String? direccion;
  final String? numero;
  final String? numeroDepartamento;
  final String? referencia;
  final String? codigoDepartamento;
  final String? codigoProvincia;
  final String? codigoDistrito;
  final double? latitud;
  final double? longitud;
  final String? slug;
  final String? observacion;
  final DateTime? createdOn;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? updatedOn;
  final int? deleteBy;
  final DateTime? deletedOn;

  OrderRestaurant({
    this.id,
    this.fecha,
    this.fechaCancelacion,
    this.fechaRechazo,
    this.fechaAceptacion,
    this.fechaEnvio,
    this.fechaEntrega,
    this.motivoRechazo,
    this.tipo,
    this.estado,
    this.estadoOnline,
    this.confirmado,
    this.tipoDocumentoOnline,
    this.numeroDocumentoOnline,
    this.envio,
    this.tiempoEntrega,
    this.numeroOrden,
    this.numeroComensales,
    this.montoDelivery,
    this.comandas,
    this.cuentas,
    this.tipoDocumentoReceptor,
    this.numeroDocumentoReceptor,
    this.denominacionReceptor,
    this.direccionReceptor,
    this.emailReceptor,
    this.telefonoReceptor,
    this.cliente,
    this.nombreCliente,
    this.usuario,
    this.mesa,
    this.empresa,
    this.empresaAdjunta,
    this.puntoVenta,
    this.tipoDireccion,
    this.formaPago,
    this.nombreFormaPago,
    this.requiereConfirmacionPago,
    this.direccionCompleta,
    this.direccion,
    this.numero,
    this.numeroDepartamento,
    this.referencia,
    this.codigoDepartamento,
    this.codigoProvincia,
    this.codigoDistrito,
    this.latitud,
    this.longitud,
    this.slug,
    this.observacion,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
  });

  factory OrderRestaurant.fromJson(Map<String, dynamic> json) => OrderRestaurant(
    id: json['id'],
    fecha: json['fecha'] != null ? parseDateTimeFlexible(DateTime.parse(json['fecha'])) : null,
    fechaCancelacion: json['fechaCancelacion'] != null ? parseDateTimeFlexible(DateTime.parse(json['fechaCancelacion'])) : null,
    fechaRechazo: json['fechaRechazo'] != null ? parseDateTimeFlexible(DateTime.parse(json['fechaRechazo'])) : null,
    fechaAceptacion: json['fechaAceptacion'] != null ? parseDateTimeFlexible(DateTime.parse(json['fechaAceptacion'])) : null,
    fechaEnvio: json['fechaEnvio'] != null ? parseDateTimeFlexible(DateTime.parse(json['fechaEnvio'])) : null,
    fechaEntrega: json['fechaEntrega'] != null ? parseDateTimeFlexible(DateTime.parse(json['fechaEntrega'])) : null,
    motivoRechazo: json['motivoRechazo'],
    tipo: json['tipo'],
    estado: json['estado'],
    estadoOnline: json['estadoOnline'],
    confirmado: json['confirmado'],
    tipoDocumentoOnline: json['tipoDocumentoOnline'],
    numeroDocumentoOnline: json['numeroDocumentoOnline'],
    envio: json['envio'] != null ? Delivery.fromJson(json['envio']) : null,
    tiempoEntrega: json['tiempoEntrega'],
    numeroOrden: json['numeroOrden'],
    numeroComensales: json['numeroComensales'],
    montoDelivery: json['montoDelivery'],
    comandas: json['comandas'] != null ? List<Command>.from(json['comandas'].map((x) => Command.fromJson(x))) : null,
    cuentas: json['cuentas'] != null ? List<Check>.from(json['cuentas'].map((x) => Check.fromJson(x))) : null,
    tipoDocumentoReceptor: json['tipoDocumentoReceptor'],
    numeroDocumentoReceptor: json['numeroDocumentoReceptor'],
    denominacionReceptor: json['denominacionReceptor'],
    direccionReceptor: json['direccionReceptor'],
    emailReceptor: json['emailReceptor'],
    telefonoReceptor: json['telefonoReceptor'],
    cliente: json['cliente'] != null ? Customer.fromJson(json['cliente']) : null,
    nombreCliente: json['nombreCliente'],
    usuario: json['usuario'] != null ? User.fromJson(json['usuario']) : null,
    mesa: json['mesa'] != null ? Table.fromJson(json['mesa']) : null,
    empresa: json['empresa'] != null ? Company.fromJson(json['empresa']) : null,
    empresaAdjunta: json['empresaAdjunta'] != null ? AttachedCompany.fromJson(json['empresaAdjunta']) : null,
    puntoVenta: json['puntoVenta'] != null ? Office.fromJson(json['puntoVenta']) : null,
    tipoDireccion: json['tipoDireccion'],
    formaPago: json['formaPago'],
    nombreFormaPago: json['nombreFormaPago'],
    requiereConfirmacionPago: json['requiereConfirmacionPago'],
    direccionCompleta: json['direccionCompleta'],
    direccion: json['direccion'],
    numero: json['numero'],
    numeroDepartamento: json['numeroDepartamento'],
    referencia: json['referencia'],
    codigoDepartamento: json['codigoDepartamento'],
    codigoProvincia: json['codigoProvincia'],
    codigoDistrito: json['codigoDistrito'],
    latitud: json['latitud'],
    longitud: json['longitud'],
    slug: json['slug'],
    observacion: json['observacion'],
    createdOn: json['createdOn'] != null ? parseDateTimeFlexible(json['createdOn']) : null,
    createdBy: json['createdBy'],
    updatedBy: json['updatedBy'],
    updatedOn: json['updatedOn'] != null ? parseDateTimeFlexible(json['updatedOn']) : null,
    deleteBy: json['deleteBy'],
    deletedOn: json['deletedOn'] != null ? parseDateTimeFlexible(json['deletedOn']) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fecha': fecha?.toIso8601String(),
    'fechaCancelacion': fechaCancelacion?.toIso8601String(),
    'fechaRechazo': fechaRechazo?.toIso8601String(),
    'fechaAceptacion': fechaAceptacion?.toIso8601String(),
    'fechaEnvio': fechaEnvio?.toIso8601String(),
    'fechaEntrega': fechaEntrega?.toIso8601String(),
    'motivoRechazo': motivoRechazo,
    'tipo': tipo,
    'estado': estado,
    'estadoOnline': estadoOnline,
    'confirmado': confirmado,
    'tipoDocumentoOnline': tipoDocumentoOnline,
    'numeroDocumentoOnline': numeroDocumentoOnline,
    'envio': envio?.toJson(),
    'tiempoEntrega': tiempoEntrega,
    'numeroOrden': numeroOrden,
    'numeroComensales': numeroComensales,
    'montoDelivery': montoDelivery,
    'comandas': comandas?.map((x) => x.toJson()).toList(),
    'cuentas': cuentas?.map((x) => x.toJson()).toList(),
    'tipoDocumentoReceptor': tipoDocumentoReceptor,
    'numeroDocumentoReceptor': numeroDocumentoReceptor,
    'denominacionReceptor': denominacionReceptor,
    'direccionReceptor': direccionReceptor,
    'emailReceptor': emailReceptor,
    'telefonoReceptor': telefonoReceptor,
    'cliente': cliente?.toJson(),
    'nombreCliente': nombreCliente,
    'usuario': usuario?.toJson(),
    'mesa': mesa?.toJson(),
    'empresa': empresa?.toJson(),
    'empresaAdjunta': empresaAdjunta?.toJson(),
    'puntoVenta': puntoVenta?.toJson(),
    'tipoDireccion': tipoDireccion,
    'formaPago': formaPago,
    'nombreFormaPago': nombreFormaPago,
    'requiereConfirmacionPago': requiereConfirmacionPago,
    'direccionCompleta': direccionCompleta,
    'direccion': direccion,
    'numero': numero,
    'numeroDepartamento': numeroDepartamento,
    'referencia': referencia,
    'codigoDepartamento': codigoDepartamento,
    'codigoProvincia': codigoProvincia,
    'codigoDistrito': codigoDistrito,
    'latitud': latitud,
    'longitud': longitud,
    'slug': slug,
    'observacion': observacion,
    'createdOn': createdOn?.toIso8601String(),
    'createdBy': createdBy,
    'updatedBy': updatedBy,
    'updatedOn': updatedOn?.toIso8601String(),
    'deleteBy': deleteBy,
    'deletedOn': deletedOn?.toIso8601String(),
  };
}
