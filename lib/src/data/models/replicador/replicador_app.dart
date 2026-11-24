enum NotificationAppType {
  yape('YAPE', 'Yape'),
  bbva('BBVA', 'BBVA - Plin'),
  interbank('INTERBANK', 'Interbank - Plin');

  final String code;
  final String label;

  const NotificationAppType(this.code, this.label);

  static NotificationAppType fromCode(String code) =>
      values.firstWhere((type) => type.code == code);
}

class ReplicadorApp {
  final NotificationAppType type;
  final String name;
  final bool selected;

  const ReplicadorApp({
    required this.type,
    required this.name,
    required this.selected,
  });

  factory ReplicadorApp.fromJson(Map<String, dynamic> json) => ReplicadorApp(
    type: NotificationAppType.fromCode(json['tipoApp'].toString()),
    name: json['nombre']?.toString() ?? '',
    selected: json['seleccionada'] == true,
  );
}
