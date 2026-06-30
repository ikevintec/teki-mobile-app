class EstadoSunatResponse {
  final String descripcion;
  final String codigo;

  EstadoSunatResponse({required this.descripcion, required this.codigo});

  factory EstadoSunatResponse.fromJson(Map<String, dynamic> json) {
    return EstadoSunatResponse(
      descripcion: json['descripcion'] ?? '',
      codigo: json['codigo'] ?? '',
    );
  }
}
