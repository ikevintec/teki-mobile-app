class FileStorage {
  final int? id;
  final String? bucket;
  final String? nombreGenerado;
  final String? nombreOriginal;
  final bool? estado;

  FileStorage({
    this.id,
    this.bucket,
    this.nombreGenerado,
    this.nombreOriginal,
    this.estado,
  });

  factory FileStorage.fromJson(Map<String, dynamic> json) => FileStorage(
        id: json['id'],
        bucket: json['bucket'],
        nombreGenerado: json['nombreGenerado'],
        nombreOriginal: json['nombreOriginal'],
        estado: json['estado'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'bucket': bucket,
        'nombreGenerado': nombreGenerado,
        'nombreOriginal': nombreOriginal,
        'estado': estado,
      };
}
