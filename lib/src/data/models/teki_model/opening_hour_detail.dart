class Openighourdetail {
  final int? id;
  final String? dia;
  final String? horaInicio;
  final String? horaFin;

  Openighourdetail({
    this.id,
    this.dia,
    this.horaInicio,
    this.horaFin,
  });

  factory Openighourdetail.fromJson(Map<String, dynamic> json) =>
      Openighourdetail(
        id: json['id'],
        dia: json['dia'],
        horaInicio: json['horaInicio'],
        horaFin: json['horaFin'],
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'dia': dia,
        'horaInicio': horaInicio,
        'horaFin': horaFin,
      };
}
