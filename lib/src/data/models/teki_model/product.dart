import 'package:teki_app/src/data/models/teki_model/brand.dart';
import 'package:teki_app/src/data/models/teki_model/category.dart';
import 'package:teki_app/src/data/models/teki_model/company.dart';
import 'package:teki_app/src/data/models/teki_model/contract_plan.dart';
import 'package:teki_app/src/data/models/teki_model/group.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/product_item_package.dart';
import 'package:teki_app/src/data/models/teki_model/product_plan_field.dart';
import 'package:teki_app/src/data/models/teki_model/product_preparation.dart';
import 'package:teki_app/src/data/models/teki_model/product_image.dart';
import 'package:teki_app/src/data/models/teki_model/product_price.dart';
import 'package:teki_app/src/data/models/teki_model/product_purchase_price.dart';
import 'package:teki_app/src/data/models/teki_model/product_related.dart';
import 'package:teki_app/src/data/models/teki_model/product_supply.dart';
import 'package:teki_app/src/data/models/teki_model/unit_code.dart';

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
  final List<ProductImage>? imagenes;
  final double? peso;
  final Company? empresa;
  final Brand? marca;
  final Category? categoria;
  final bool? envaseRetornable;
  final Product? productoEnvase;
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
  final bool? ocultarEnBuscadorVentas;
  final bool? mostrarEnWeb;
  final bool? favorito;
  final bool? estado;
  final bool? validacionLote;
  final double? precioCompraUnidad;

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
    this.imagenes,
    this.peso,
    this.empresa,
    this.marca,
    this.categoria,
    this.envaseRetornable,
    this.productoEnvase,
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
    this.ocultarEnBuscadorVentas,
    this.mostrarEnWeb,
    this.favorito,
    this.estado,
    this.validacionLote,
    this.precioCompraUnidad,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'],
        codigo: json['codigo'],
        codigoBarra: json['codigoBarra'],
        nombre: json['nombre'],
        detalle: json['detalle'],
        moneda: json['moneda'],
        unidadCompra: json['unidadCompra'] != null
            ? UnitCode.fromJson(json['unidadCompra'])
            : null,
        unidad:
            json['unidad'] != null ? UnitCode.fromJson(json['unidad']) : null,
        unidadAlternativa: json['unidadAlternativa'] != null
            ? UnitCode.fromJson(json['unidadAlternativa'])
            : null,
        factorUnidadAlternativa:
            (json['factorUnidadAlternativa'] as num?)?.toDouble(),
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
        precioCompraReferencial:
            (json['precioCompraReferencial'] as num?)?.toDouble(),
        monedaReferencial: json['monedaReferencial'],
        preciosPorPuntoVenta: json['preciosPorPuntoVenta'],
        preciosVenta: (json['preciosVenta'] as List?)
            ?.map((e) => ProductPrice.fromJson(e))
            .toList(),
        preciosCompra: (json['preciosCompra'] as List?)
            ?.map((e) => ProductPurchasePrice.fromJson(e))
            .toList(),
        inventarioMinimo: (json['inventarioMinimo'] as num?)?.toDouble(),
        inventarioMaximo: (json['inventarioMaximo'] as num?)?.toDouble(),
        igv: json['igv'],
        tipoAfectacion: json['tipoAfectacion'],
        imagenes: (json['imagenes'] as List?)
            ?.map((e) => ProductImage.fromJson(e))
            .toList(),
        peso: (json['peso'] as num?)?.toDouble(),
        empresa:
            json['empresa'] != null ? Company.fromJson(json['empresa']) : null,
        marca: json['marca'] != null ? Brand.fromJson(json['marca']) : null,
        envaseRetornable: json['envaseRetornable'],
        productoEnvase: json['productoEnvase'] != null ? Product.fromJson(json['productoEnvase']) : null,
        categoria: json['categoria'] != null
            ? Category.fromJson(json['categoria'])
            : null,
        numeroMesesPlan: json['numeroMesesPlan'],
        numeroDiasPlan: json['numeroDiasPlan'],
        numeroCuotasPlan: json['numeroCuotasPlan'],
        intervaloCuotasDiasPlan: json['intervaloCuotasDiasPlan'],
        porcentajeOtrosCargos:
            (json['porcentajeOtrosCargos'] as num?)?.toDouble(),
        numeroHorasPlan: json['numeroHorasPlan'],
        numeroMinutosPlan: json['numeroMinutosPlan'],
        diasCreditoPlan: json['diasCreditoPlan'],
        tieneImpuestoBolsas: json['tieneImpuestoBolsas'],
        loteSerie: json['loteSerie'],
        tipoLote: json['tipoLote'],
        planCampos: (json['planCampos'] as List?)
            ?.map((e) => ProductPlanField.fromJson(e))
            .toList(),
        planContratos: (json['planContratos'] as List?)
            ?.map((e) => ContractPlan.fromJson(e))
            .toList(),
        comboPlatillos: (json['comboPlatillos'] as List?)
            ?.map((e) => Product.fromJson(e))
            .toList(),
        puntosDeVenta: (json['puntosDeVenta'] as List?)
            ?.map((e) => Office.fromJson(e))
            .toList(),
        insumos: (json['insumos'] as List?)
            ?.map((e) => ProductSupply.fromJson(e))
            .toList(),
        productosRelacionados: (json['productosRelacionados'] as List?)
            ?.map((e) => ProductRelated.fromJson(e))
            .toList(),
        paqueteItems: (json['paqueteItems'] as List?)
            ?.map((e) => ProductItemPackage.fromJson(e))
            .toList(),
        grupos:
            (json['grupos'] as List?)?.map((e) => Group.fromJson(e)).toList(),
        preparaciones: (json['preparaciones'] as List?)
            ?.map((e) => ProductPreparation.fromJson(e))
            .toList(),
        tipoProducto: json['tipoProducto'],
        mostrarEnRestaurante: json['mostrarEnRestaurante'],
        ocultarEnBuscadorVentas: json['ocultarEnBuscadorVentas'],
        mostrarEnWeb: json['mostrarEnWeb'],
        favorito: json['favorito'],
        estado: json['estado'],
        validacionLote: json['validacionLote'],
        inventarios: (json['inventarios'] as List?)
            ?.map((e) => Inventory.fromJson(e))
            .toList(),
        precioCompraUnidad: (json['precioCompraUnidad'] as num?)?.toDouble(),
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
        'imagenes': imagenes?.map((e) => e.toJson()).toList(),
        'peso': peso,
        'empresa': empresa?.toJson(),
        'marca': marca?.toJson(),
        'categoria': categoria?.toJson(),
        'envaseRetornable': envaseRetornable,
        'productoEnvase': productoEnvase == null ? null : {'id': productoEnvase!.id, 'nombre': productoEnvase!.nombre},
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
        'productosRelacionados':
            productosRelacionados?.map((e) => e.toJson()).toList(),
        'paqueteItems': paqueteItems?.map((e) => e.toJson()).toList(),
        'grupos': grupos?.map((e) => e.toJson()).toList(),
        'preparaciones': preparaciones?.map((e) => e.toJson()).toList(),
        'tipoProducto': tipoProducto,
        'mostrarEnRestaurante': mostrarEnRestaurante,
        'ocultarEnBuscadorVentas': ocultarEnBuscadorVentas,
        'mostrarEnWeb': mostrarEnWeb,
        'favorito': favorito,
        'estado': estado,
        'validacionLote': validacionLote,
        'inventarios': inventarios?.map((e) => e.toJson()).toList(),
      };

  Product copyWith({
    int? id,
    String? codigo,
    String? codigoBarra,
    String? nombre,
    String? detalle,
    String? moneda,
    UnitCode? unidadCompra,
    UnitCode? unidad,
    UnitCode? unidadAlternativa,
    double? factorUnidadAlternativa,
    double? factor,
    bool? servicio,
    bool? puedeSerVendido,
    bool? puedeSerComprado,
    bool? precioCompraIncImp,
    bool? topper,
    double? precioCompra,
    double? precioCompraNeto,
    double? precioVentaMinimo,
    double? recargoConsumo,
    double? precioCompraReferencial,
    String? monedaReferencial,
    bool? preciosPorPuntoVenta,
    List<ProductPrice>? preciosVenta,
    List<ProductPurchasePrice>? preciosCompra,
    List<Inventory>? inventarios,
    double? inventarioMinimo,
    double? inventarioMaximo,
    bool? igv,
    String? tipoAfectacion,
    List<ProductImage>? imagenes,
    double? peso,
    Company? empresa,
    Brand? marca,
    Category? categoria,
    bool? envaseRetornable,
    Product? productoEnvase,
    int? numeroMesesPlan,
    int? numeroDiasPlan,
    int? numeroCuotasPlan,
    int? intervaloCuotasDiasPlan,
    double? porcentajeOtrosCargos,
    int? numeroHorasPlan,
    int? numeroMinutosPlan,
    int? diasCreditoPlan,
    bool? tieneImpuestoBolsas,
    bool? loteSerie,
    String? tipoLote,
    List<ProductPlanField>? planCampos,
    List<ContractPlan>? planContratos,
    List<Product>? comboPlatillos,
    List<Office>? puntosDeVenta,
    List<ProductSupply>? insumos,
    List<ProductRelated>? productosRelacionados,
    List<ProductItemPackage>? paqueteItems,
    List<Group>? grupos,
    List<ProductPreparation>? preparaciones,
    String? tipoProducto,
    bool? mostrarEnRestaurante,
    bool? ocultarEnBuscadorVentas,
    bool? mostrarEnWeb,
    bool? favorito,
    bool? estado,
    bool? validacionLote,
    double? precioCompraUnidad,
  }) {
    return Product(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      codigoBarra: codigoBarra ?? this.codigoBarra,
      nombre: nombre ?? this.nombre,
      detalle: detalle ?? this.detalle,
      moneda: moneda ?? this.moneda,
      unidadCompra: unidadCompra ?? this.unidadCompra,
      unidad: unidad ?? this.unidad,
      unidadAlternativa: unidadAlternativa ?? this.unidadAlternativa,
      factorUnidadAlternativa:
          factorUnidadAlternativa ?? this.factorUnidadAlternativa,
      factor: factor ?? this.factor,
      servicio: servicio ?? this.servicio,
      puedeSerVendido: puedeSerVendido ?? this.puedeSerVendido,
      puedeSerComprado: puedeSerComprado ?? this.puedeSerComprado,
      precioCompraIncImp: precioCompraIncImp ?? this.precioCompraIncImp,
      topper: topper ?? this.topper,
      precioCompra: precioCompra ?? this.precioCompra,
      precioCompraNeto: precioCompraNeto ?? this.precioCompraNeto,
      precioVentaMinimo: precioVentaMinimo ?? this.precioVentaMinimo,
      recargoConsumo: recargoConsumo ?? this.recargoConsumo,
      precioCompraReferencial:
          precioCompraReferencial ?? this.precioCompraReferencial,
      monedaReferencial: monedaReferencial ?? this.monedaReferencial,
      preciosPorPuntoVenta: preciosPorPuntoVenta ?? this.preciosPorPuntoVenta,
      preciosVenta: preciosVenta ?? this.preciosVenta,
      preciosCompra: preciosCompra ?? this.preciosCompra,
      inventarios: inventarios ?? this.inventarios,
      inventarioMinimo: inventarioMinimo ?? this.inventarioMinimo,
      inventarioMaximo: inventarioMaximo ?? this.inventarioMaximo,
      igv: igv ?? this.igv,
      tipoAfectacion: tipoAfectacion ?? this.tipoAfectacion,
      imagenes: imagenes ?? this.imagenes,
      peso: peso ?? this.peso,
      empresa: empresa ?? this.empresa,
      marca: marca ?? this.marca,
      categoria: categoria ?? this.categoria,
      envaseRetornable: envaseRetornable ?? this.envaseRetornable,
      productoEnvase: productoEnvase ?? this.productoEnvase,
      numeroMesesPlan: numeroMesesPlan ?? this.numeroMesesPlan,
      numeroDiasPlan: numeroDiasPlan ?? this.numeroDiasPlan,
      numeroCuotasPlan: numeroCuotasPlan ?? this.numeroCuotasPlan,
      intervaloCuotasDiasPlan:
          intervaloCuotasDiasPlan ?? this.intervaloCuotasDiasPlan,
      porcentajeOtrosCargos:
          porcentajeOtrosCargos ?? this.porcentajeOtrosCargos,
      numeroHorasPlan: numeroHorasPlan ?? this.numeroHorasPlan,
      numeroMinutosPlan: numeroMinutosPlan ?? this.numeroMinutosPlan,
      diasCreditoPlan: diasCreditoPlan ?? this.diasCreditoPlan,
      tieneImpuestoBolsas: tieneImpuestoBolsas ?? this.tieneImpuestoBolsas,
      loteSerie: loteSerie ?? this.loteSerie,
      tipoLote: tipoLote ?? this.tipoLote,
      planCampos: planCampos ?? this.planCampos,
      planContratos: planContratos ?? this.planContratos,
      comboPlatillos: comboPlatillos ?? this.comboPlatillos,
      puntosDeVenta: puntosDeVenta ?? this.puntosDeVenta,
      insumos: insumos ?? this.insumos,
      productosRelacionados:productosRelacionados ?? this.productosRelacionados,
      paqueteItems: paqueteItems ?? this.paqueteItems,
      grupos: grupos ?? this.grupos,
      preparaciones: preparaciones ?? this.preparaciones,
      tipoProducto: tipoProducto ?? this.tipoProducto,
      mostrarEnRestaurante: mostrarEnRestaurante ?? this.mostrarEnRestaurante,
      ocultarEnBuscadorVentas: ocultarEnBuscadorVentas ?? this.ocultarEnBuscadorVentas,
      mostrarEnWeb: mostrarEnWeb ?? this.mostrarEnWeb,
      favorito: favorito ?? this.favorito,
      estado: estado ?? this.estado,
      validacionLote: validacionLote ?? this.validacionLote,
      precioCompraUnidad: precioCompraUnidad ?? this.precioCompraUnidad,
    );
  }

  /// Imagen a mostrar del producto: busca en `imagenes` la marcada como
  /// `porDefecto` y no `eliminado`; si no hay, devuelve la primera no eliminada.
  ProductImage? get imagenPorDefecto {
    final imgs = imagenes;
    if (imgs == null || imgs.isEmpty) return null;
    ProductImage? primeraActiva;
    for (final img in imgs) {
      if (img.eliminado == true) continue;
      primeraActiva ??= img;
      if (img.porDefecto == true) return img;
    }
    return primeraActiva;
  }
}
