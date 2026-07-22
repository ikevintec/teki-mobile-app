import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/utils/formats.dart';

class ProductPrice {
  final int? id;
  final double? precio;
  final double? precioNeto;
  final double? margenUtilidad;
  final double? unidadesMayoreo;
  final String? tipoPrecio;
  final String? nombre;
  final Office? puntoVenta;
  final User? usuario;
  final DateTime? fecha;
  final Product? producto;

  ProductPrice({
    this.id,
    this.precio,
    this.precioNeto,
    this.margenUtilidad,
    this.unidadesMayoreo,
    this.tipoPrecio,
    this.nombre,
    this.puntoVenta,
    this.usuario,
    this.fecha,
    this.producto,
  });

  factory ProductPrice.fromJson(Map<String, dynamic> json) => ProductPrice(
        id: json['id'],
        precio: (json['precio'] as num?)?.toDouble(),
        precioNeto: (json['precioNeto'] as num?)?.toDouble(),
        margenUtilidad: (json['margenUtilidad'] as num?)?.toDouble(),
        unidadesMayoreo: (json['unidadesMayoreo'] as num?)?.toDouble(),
        tipoPrecio: json['tipoPrecio'],
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
        'id': id,
        'precio': precio,
        'precioNeto': precioNeto,
        'margenUtilidad': margenUtilidad,
        'unidadesMayoreo': unidadesMayoreo,
        'tipoPrecio': tipoPrecio,
        'nombre': nombre,
        'puntoVenta': puntoVenta?.toJson(),
        'usuario': usuario?.toJson(),
        'fecha': fecha?.toIso8601String(),
        'producto': producto?.toJson(),
      };
}

extension ProductPriceCopyWith on ProductPrice {
  ProductPrice copyWith({
    int? id,
    double? precio,
    double? precioNeto,
    double? margenUtilidad,
    double? unidadesMayoreo,
    String? tipoPrecio,
    String? nombre,
    Office? puntoVenta,
    User? usuario,
    DateTime? fecha,
    Product? producto,
  }) {
    return ProductPrice(
      id: id ?? this.id,
      precio: precio ?? this.precio,
      precioNeto: precioNeto ?? this.precioNeto,
      margenUtilidad: margenUtilidad ?? this.margenUtilidad,
      unidadesMayoreo: unidadesMayoreo ?? this.unidadesMayoreo,
      tipoPrecio: tipoPrecio ?? this.tipoPrecio,
      nombre: nombre ?? this.nombre,
      puntoVenta: puntoVenta ?? this.puntoVenta,
      usuario: usuario ?? this.usuario,
      fecha: fecha ?? this.fecha,
      producto: producto ?? this.producto,
    );
  }
}

