class PreparationOption {
  int? id;
  String? opcion;
  bool? modificado;
  bool? eliminado;
  DateTime? createdOn;
  int? createdBy;
  int? updatedBy;
  DateTime? updatedOn;
  int? deleteBy;
  DateTime? deletedOn;

  PreparationOption({
    this.id,
    this.opcion,
    this.modificado,
    this.eliminado,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
  });

  factory PreparationOption.fromJson(Map<String, dynamic> json) {
    return PreparationOption(
      id: json['id'],
      opcion: json['opcion'],
      modificado: json['modificado'],
      eliminado: json['eliminado'],
      createdOn:
          json['createdOn'] != null ? DateTime.parse(json['createdOn']) : null,
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      updatedOn:
          json['updatedOn'] != null ? DateTime.parse(json['updatedOn']) : null,
      deleteBy: json['deleteBy'],
      deletedOn:
          json['deletedOn'] != null ? DateTime.parse(json['deletedOn']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'opcion': opcion,
      'modificado': modificado,
      'eliminado': eliminado,
      'createdOn': createdOn?.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'updatedOn': updatedOn?.toIso8601String(),
      'deleteBy': deleteBy,
      'deletedOn': deletedOn?.toIso8601String(),
    };
  }
}
