class City{
  final int? id;
  final String? codigoCiudad;
  final String? ciudad;
  final String? codDepartamento;
  final String? codProvincia;
  final String? codDistrito;
  final String? nombreDepartamento;
  final String? nombreProvincia;
  final String? nombreDistrito;
  final String? nombreDepartamentoGoogleMaps;
  final String? nombreProvinciaGoogleMaps;
  final String? nombreDistritoGoogleMaps;

  City({
    this.id,
    this.codigoCiudad,
    this.ciudad,
    this.codDepartamento,
    this.codProvincia,
    this.codDistrito,
    this.nombreDepartamento,
    this.nombreProvincia,
    this.nombreDistrito,
    this.nombreDepartamentoGoogleMaps,
    this.nombreProvinciaGoogleMaps,
    this.nombreDistritoGoogleMaps,
  });

  factory City.fromJson(Map<String, dynamic> json) => City(
    id: json['id'],
    codigoCiudad: json['codigoCiudad'],
    ciudad: json['ciudad'],
    codDepartamento: json['codDepartamento'],
    codProvincia: json['codProvincia'],
    codDistrito: json['codDistrito'],
    nombreDepartamento: json['nombreDepartamento'],
    nombreProvincia: json['nombreProvincia'],
    nombreDistrito: json['nombreDistrito'],
    nombreDepartamentoGoogleMaps: json['nombreDepartamentoGoogleMaps'],
    nombreProvinciaGoogleMaps: json['nombreProvinciaGoogleMaps'],
    nombreDistritoGoogleMaps: json['nombreDistritoGoogleMaps'],
  );
    Map<String, dynamic> toJson() => {
        'id': id,
        'codigoCiudad': codigoCiudad,
        'ciudad': ciudad,
        'codDepartamento': codDepartamento,
        'codProvincia': codProvincia,
        'codDistrito': codDistrito,
        'nombreDepartamento': nombreDepartamento,
        'nombreProvincia': nombreProvincia,
        'nombreDistrito': nombreDistrito,
        'nombreDepartamentoGoogleMaps': nombreDepartamentoGoogleMaps,
        'nombreProvinciaGoogleMaps': nombreProvinciaGoogleMaps,
        'nombreDistritoGoogleMaps': nombreDistritoGoogleMaps,
      };
}