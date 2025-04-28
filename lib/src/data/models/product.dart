
import 'package:teki_app/src/data/models/brand.dart';
import 'package:teki_app/src/data/models/category.dart';
import 'package:teki_app/src/data/models/company.dart';
import 'package:teki_app/src/data/models/contractPlan.dart';
import 'package:teki_app/src/data/models/group.dart';
import 'package:teki_app/src/data/models/inventory.dart';
import 'package:teki_app/src/data/models/office.dart';
import 'package:teki_app/src/data/models/productItemPackage.dart';
import 'package:teki_app/src/data/models/productPlanField.dart';
import 'package:teki_app/src/data/models/productPreparation.dart';
import 'package:teki_app/src/data/models/productPrice.dart';
import 'package:teki_app/src/data/models/productPurchasePrice.dart';
import 'package:teki_app/src/data/models/productRelated.dart';
import 'package:teki_app/src/data/models/productSupply.dart';
import 'package:teki_app/src/data/models/unitCode.dart';

class Product {
  final int? id;
  final String? codigo;
  final String? codigoBarra;
  final String? nombre;
  final String? detalle;
  final String? moneda;
  final UnitCode? unidadCompra;
  final UnitCode? unidad;
  final UnitCode? unidadAlternativa;
  final double? factorUnidadAlternativa;
  final double? factor;
  final bool? servicio;
  final bool? puedeSerVendido;
  final bool? puedeSerComprado;
  final bool? precioCompraIncImp;
  final bool? topper;
  final double? precioCompra;
  final double? precioCompraNeto;
  final double? precioVentaMinimo;
  final double? recargoConsumo;
  final double? precioCompraReferencial;
  final String? monedaReferencial;
  final bool? preciosPorPuntoVenta;
  final List<ProductPrice>? preciosVenta;
  final List<ProductPurchasePrice>? preciosCompra;
  final double? inventarioMinimo;
  final double? inventarioMaximo;
  final List<Inventory>? inventarios;
  final bool? igv;
  final String? tipoAfectacion;
  late final String? imagenUrl;
  final double? peso;
  final Company? empresa;
  final Brand? marca;
  final Category? categoria;
  final int? numeroMesesPlan;
  final int? numeroDiasPlan;
  final int? numeroCuotasPlan;
  final int? intervaloCuotasDiasPlan;
  final double? porcentajeOtrosCargos;
  final int? numeroHorasPlan;
  final int? numeroMinutosPlan;
  final int? diasCreditoPlan;
  final bool? tieneImpuestoBolsas;
  final bool? loteSerie;
  final String? tipoLote;
  final List<ProductPlanField>? planCampos;
  final List<ContractPlan>? planContratos;
  final List<Product>? comboPlatillos;
  final List<Office>? puntosDeVenta;
  final List<ProductSupply>? insumos;
  final List<ProductRelated>? productosRelacionados;
  final List<ProductItemPackage>? paqueteItems;
  final List<Group>? grupos;
  final List<ProductPreparation>? preparaciones;
  final String? tipoProducto;
  final bool? mostrarEnRestaurante;
  final bool? mostrarEnWeb;
  final bool? favorito;
  final bool? estado;
  final bool? validacionLote;

  Product({
    this.id,
    this.codigo,
    this.codigoBarra,
    this.nombre,
    this.detalle,
    this.moneda,
    this.unidadCompra,
    this.unidad,
    this.unidadAlternativa,
    this.factorUnidadAlternativa,
    this.factor,
    this.servicio,
    this.puedeSerVendido,
    this.puedeSerComprado,
    this.precioCompraIncImp,
    this.topper,
    this.precioCompra,
    this.precioCompraNeto,
    this.precioVentaMinimo,
    this.recargoConsumo,
    this.precioCompraReferencial,
    this.monedaReferencial,
    this.preciosPorPuntoVenta,
    this.preciosVenta,
    this.preciosCompra,
    this.inventarios,
    this.inventarioMinimo,
    this.inventarioMaximo,
    this.igv,
    this.tipoAfectacion,
    this.imagenUrl,
    this.peso,
    this.empresa,
    this.marca,
    this.categoria,
    this.numeroMesesPlan,
    this.numeroDiasPlan,
    this.numeroCuotasPlan,
    this.intervaloCuotasDiasPlan,
    this.porcentajeOtrosCargos,
    this.numeroHorasPlan,
    this.numeroMinutosPlan,
    this.diasCreditoPlan,
    this.tieneImpuestoBolsas,
    this.loteSerie,
    this.tipoLote,
    this.planCampos,
    this.planContratos,
    this.comboPlatillos,
    this.puntosDeVenta,
    this.insumos,
    this.productosRelacionados,
    this.paqueteItems,
    this.grupos,
    this.preparaciones,
    this.tipoProducto,
    this.mostrarEnRestaurante,
    this.mostrarEnWeb,
    this.favorito,
    this.estado,
    this.validacionLote,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'],
        codigo: json['codigo'],
        codigoBarra: json['codigoBarra'],
        nombre: json['nombre'],
        detalle: json['detalle'],
        moneda: json['moneda'],
        unidadCompra: json['unidadCompra'] != null ? UnitCode.fromJson(json['unidadCompra']) : null,
        unidad: json['unidad'] != null ? UnitCode.fromJson(json['unidad']) : null,
        unidadAlternativa: json['unidadAlternativa'] != null ? UnitCode.fromJson(json['unidadAlternativa']) : null,
        factorUnidadAlternativa: (json['factorUnidadAlternativa'] as num?)?.toDouble(),
        factor: (json['factor'] as num?)?.toDouble(),
        servicio: json['servicio'],
        puedeSerVendido: json['puedeSerVendido'],
        puedeSerComprado: json['puedeSerComprado'],
        precioCompraIncImp: json['precioCompraIncImp'],
        topper: json['topper'],
        precioCompra: (json['precioCompra'] as num?)?.toDouble(),
        precioCompraNeto: (json['precioCompraNeto'] as num?)?.toDouble(),
        precioVentaMinimo: (json['precioVentaMinimo'] as num?)?.toDouble(),
        recargoConsumo: (json['recargoConsumo'] as num?)?.toDouble(),
        precioCompraReferencial: (json['precioCompraReferencial'] as num?)?.toDouble(),
        monedaReferencial: json['monedaReferencial'],
        preciosPorPuntoVenta: json['preciosPorPuntoVenta'],
        preciosVenta: (json['preciosVenta'] as List?)?.map((e) => ProductPrice.fromJson(e)).toList(),
        preciosCompra: (json['preciosCompra'] as List?)?.map((e) => ProductPurchasePrice.fromJson(e)).toList(),
        inventarioMinimo: (json['inventarioMinimo'] as num?)?.toDouble(),
        inventarioMaximo: (json['inventarioMaximo'] as num?)?.toDouble(),
        igv: json['igv'],
        tipoAfectacion: json['tipoAfectacion'],
        imagenUrl: json['imagenUrl'],
        peso: (json['peso'] as num?)?.toDouble(),
        empresa: json['empresa'] != null ? Company.fromJson(json['empresa']) : null,
        marca: json['marca'] != null ? Brand.fromJson(json['marca']) : null,
        categoria: json['categoria'] != null ? Category.fromJson(json['categoria']) : null,
        numeroMesesPlan: json['numeroMesesPlan'],
        numeroDiasPlan: json['numeroDiasPlan'],
        numeroCuotasPlan: json['numeroCuotasPlan'],
        intervaloCuotasDiasPlan: json['intervaloCuotasDiasPlan'],
        porcentajeOtrosCargos: (json['porcentajeOtrosCargos'] as num?)?.toDouble(),
        numeroHorasPlan: json['numeroHorasPlan'],
        numeroMinutosPlan: json['numeroMinutosPlan'],
        diasCreditoPlan: json['diasCreditoPlan'],
        tieneImpuestoBolsas: json['tieneImpuestoBolsas'],
        loteSerie: json['loteSerie'],
        tipoLote: json['tipoLote'],
        planCampos: (json['planCampos'] as List?)?.map((e) => ProductPlanField.fromJson(e)).toList(),
        planContratos: (json['planContratos'] as List?)?.map((e) => ContractPlan.fromJson(e)).toList(),
        comboPlatillos: (json['comboPlatillos'] as List?)?.map((e) => Product.fromJson(e)).toList(),
        puntosDeVenta: (json['puntosDeVenta'] as List?)?.map((e) => Office.fromJson(e)).toList(),
        insumos: (json['insumos'] as List?)?.map((e) => ProductSupply.fromJson(e)).toList(),
        productosRelacionados: (json['productosRelacionados'] as List?)?.map((e) => ProductRelated.fromJson(e)).toList(),
        paqueteItems: (json['paqueteItems'] as List?)?.map((e) => ProductItemPackage.fromJson(e)).toList(),
        grupos: (json['grupos'] as List?)?.map((e) => Group.fromJson(e)).toList(),
        preparaciones: (json['preparaciones'] as List?)?.map((e) => ProductPreparation.fromJson(e)).toList(),
        tipoProducto: json['tipoProducto'],
        mostrarEnRestaurante: json['mostrarEnRestaurante'],
        mostrarEnWeb: json['mostrarEnWeb'],
        favorito: json['favorito'],
        estado: json['estado'],
        validacionLote: json['validacionLote'],
        inventarios: (json['inventarios'] as List?)?.map((e) => Inventory.fromJson(e)).toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'codigo': codigo,
        'codigoBarra': codigoBarra,
        'nombre': nombre,
        'detalle': detalle,
        'moneda': moneda,
        'unidadCompra': unidadCompra?.toJson(),
        'unidad': unidad?.toJson(),
        'unidadAlternativa': unidadAlternativa?.toJson(),
        'factorUnidadAlternativa': factorUnidadAlternativa,
        'factor': factor,
        'servicio': servicio,
        'puedeSerVendido': puedeSerVendido,
        'puedeSerComprado': puedeSerComprado,
        'precioCompraIncImp': precioCompraIncImp,
        'topper': topper,
        'precioCompra': precioCompra,
        'precioCompraNeto': precioCompraNeto,
        'precioVentaMinimo': precioVentaMinimo,
        'recargoConsumo': recargoConsumo,
        'precioCompraReferencial': precioCompraReferencial,
        'monedaReferencial': monedaReferencial,
        'preciosPorPuntoVenta': preciosPorPuntoVenta,
        'preciosVenta': preciosVenta?.map((e) => e.toJson()).toList(),
        'preciosCompra': preciosCompra?.map((e) => e.toJson()).toList(),
        'inventarioMinimo': inventarioMinimo,
        'inventarioMaximo': inventarioMaximo,
        'igv': igv,
        'tipoAfectacion': tipoAfectacion,
        'imagenUrl': imagenUrl,
        'peso': peso,
        'empresa': empresa?.toJson(),
        'marca': marca?.toJson(),
        'categoria': categoria?.toJson(),
        'numeroMesesPlan': numeroMesesPlan,
        'numeroDiasPlan': numeroDiasPlan,
        'numeroCuotasPlan': numeroCuotasPlan,
        'intervaloCuotasDiasPlan': intervaloCuotasDiasPlan,
        'porcentajeOtrosCargos': porcentajeOtrosCargos,
        'numeroHorasPlan': numeroHorasPlan,
        'numeroMinutosPlan': numeroMinutosPlan,
        'diasCreditoPlan': diasCreditoPlan,
        'tieneImpuestoBolsas': tieneImpuestoBolsas,
        'loteSerie': loteSerie,
        'tipoLote': tipoLote,
        'planCampos': planCampos?.map((e) => e.toJson()).toList(),
        'planContratos': planContratos?.map((e) => e.toJson()).toList(),
        'comboPlatillos': comboPlatillos?.map((e) => e.toJson()).toList(),
        'puntosDeVenta': puntosDeVenta?.map((e) => e.toJson()).toList(),
        'insumos': insumos?.map((e) => e.toJson()).toList(),
        'productosRelacionados': productosRelacionados?.map((e) => e.toJson()).toList(),
        'paqueteItems': paqueteItems?.map((e) => e.toJson()).toList(),
        'grupos': grupos?.map((e) => e.toJson()).toList(),
        'preparaciones': preparaciones?.map((e) => e.toJson()).toList(),
        'tipoProducto': tipoProducto,
        'mostrarEnRestaurante': mostrarEnRestaurante,
        'mostrarEnWeb': mostrarEnWeb,
        'favorito': favorito,
        'estado': estado,
        'validacionLote': validacionLote,
        'inventarios': inventarios?.map((e) => e.toJson()).toList(),
      };
}
