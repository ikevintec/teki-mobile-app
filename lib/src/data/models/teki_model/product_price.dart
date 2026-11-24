import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/utils/formats.dart';

class ProductPrice {
  final int? tipoComercialId;
  final bool? estado;
  final bool? eliminado;
  final int? versionPrecio;

  final int? id;
  final double? precio;
  final double? precioNeto;
  final double? margenUtilidad;
  final double? unidadesMayoreo;
  final String? tipoPrecio;
  final bool? paraCanje;
  final String? nombre;
  final Office? puntoVenta;
  final User? usuario;
  final DateTime? fecha;
  final Product? producto;

  ProductPrice({
    this.tipoComercialId,
    this.estado,
    this.eliminado,
    this.versionPrecio,

    this.id,
    this.precio,
    this.precioNeto,
    this.margenUtilidad,
    this.unidadesMayoreo,
    this.tipoPrecio,
    this.paraCanje,
    this.nombre,
    this.puntoVenta,
    this.usuario,
    this.fecha,
    this.producto,
  });

  factory ProductPrice.fromJson(Map<String, dynamic> json) => ProductPrice(
                tipoComercialId: (json['tipoComercialId'] as num?)?.toInt(),
        estado: json['estado'] as bool?,
        eliminado: json['eliminado'] as bool?,
        versionPrecio: (json['versionPrecio'] as num?)?.toInt(),
id: json['id'],
        precio: (json['precio'] as num?)?.toDouble(),
        precioNeto: (json['precioNeto'] as num?)?.toDouble(),
        margenUtilidad: (json['margenUtilidad'] as num?)?.toDouble(),
        unidadesMayoreo: (json['unidadesMayoreo'] as num?)?.toDouble(),
        tipoPrecio: json['tipoPrecio'],
        paraCanje: json['paraCanje'],
        nombre: json['nombre'],
        puntoVenta: json['puntoVenta'] != null
            ? Office.fromJson(json['puntoVenta'])
            : null,
        usuario:json['usuario'] != null ? User.fromJson(json['usuario']) : null,
        fecha:  parseDateTimeFlexible(json['fecha']),
        producto: json['producto'] != null
            ? Product.fromJson(json['producto'])
            : null,
      );

  Map<String, dynamic> toJson() => {
                'tipoComercialId': tipoComercialId,
        'estado': estado,
        'eliminado': eliminado,
        'versionPrecio': versionPrecio,
'id': id,
        'precio': precio,
        'precioNeto': precioNeto,
        'margenUtilidad': margenUtilidad,
        'unidadesMayoreo': unidadesMayoreo,
        'tipoPrecio': tipoPrecio,
        'paraCanje': paraCanje,
        'nombre': nombre,
        'puntoVenta': puntoVenta?.toJson(),
        'usuario': usuario?.toJson(),
        'fecha': fecha?.toIso8601String(),
        'producto': producto?.toJson(),
      };
}

extension ProductPriceCopyWith on ProductPrice {
  ProductPrice copyWith({
    int? tipoComercialId,
    bool? estado,
    bool? eliminado,
    int? versionPrecio,

    int? id,
    double? precio,
    double? precioNeto,
    double? margenUtilidad,
    double? unidadesMayoreo,
    String? tipoPrecio,
    bool? paraCanje,
    String? nombre,
    Office? puntoVenta,
    User? usuario,
    DateTime? fecha,
    Product? producto,
  }) {
    return ProductPrice(
            tipoComercialId: tipoComercialId ?? this.tipoComercialId,
      estado: estado ?? this.estado,
      eliminado: eliminado ?? this.eliminado,
      versionPrecio: versionPrecio ?? this.versionPrecio,
id: id ?? this.id,
      precio: precio ?? this.precio,
      precioNeto: precioNeto ?? this.precioNeto,
      margenUtilidad: margenUtilidad ?? this.margenUtilidad,
      unidadesMayoreo: unidadesMayoreo ?? this.unidadesMayoreo,
      tipoPrecio: tipoPrecio ?? this.tipoPrecio,
      paraCanje: paraCanje ?? this.paraCanje,
      nombre: nombre ?? this.nombre,
      puntoVenta: puntoVenta ?? this.puntoVenta,
      usuario: usuario ?? this.usuario,
      fecha: fecha ?? this.fecha,
      producto: producto ?? this.producto,
    );
  }
}

