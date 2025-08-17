class DataSend {
  final int? id;
  final String nameMessage;
  final List<String> archivos;
  final String asunto;
  final List<String> emails;
  final String? number;
  final String texto;
  final String url;
  final String messageWhatsappWeb;
  final String textMessage;
  final String type;

  const DataSend({
    this.id,
    required this.nameMessage,
    required this.archivos,
    required this.asunto,
    required this.emails,
    this.number,
    required this.texto,
    required this.url,
    required this.messageWhatsappWeb,
    required this.textMessage,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameMessage': nameMessage,
      'archivos': archivos,
      'asunto': asunto,
      'emails': emails,
      'number': number,
      'texto': texto,
      'url': url,
      'messageWhatsappWeb': messageWhatsappWeb,
      'textMessage': textMessage,
      'type': type,
    };
  }

  factory DataSend.fromJson(Map<String, dynamic> json) {
    return DataSend(
      id: json['id'],
      nameMessage: json['nameMessage'] ?? '',
      archivos: List<String>.from(json['archivos'] ?? []),
      asunto: json['asunto'] ?? '',
      emails: List<String>.from(json['emails'] ?? []),
      number: json['number'],
      texto: json['texto'] ?? '',
      url: json['url'] ?? '',
      messageWhatsappWeb: json['messageWhatsappWeb'] ?? '',
      textMessage: json['textMessage'] ?? '',
      type: json['type'] ?? '',
    );
  }

  DataSend copyWith({
    int? id,
    String? nameMessage,
    List<String>? archivos,
    String? asunto,
    List<String>? emails,
    String? number,
    String? texto,
    String? url,
    String? messageWhatsappWeb,
    String? textMessage,
    String? type,
  }) {
    return DataSend(
      id: id ?? this.id,
      nameMessage: nameMessage ?? this.nameMessage,
      archivos: archivos ?? this.archivos,
      asunto: asunto ?? this.asunto,
      emails: emails ?? this.emails,
      number: number ?? this.number,
      texto: texto ?? this.texto,
      url: url ?? this.url,
      messageWhatsappWeb: messageWhatsappWeb ?? this.messageWhatsappWeb,
      textMessage: textMessage ?? this.textMessage,
      type: type ?? this.type,
    );
  }

  @override
  String toString() {
    return 'DataSend(id: $id, nameMessage: $nameMessage, number: $number, url: $url, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DataSend &&
        other.id == id &&
        other.nameMessage == nameMessage &&
        other.number == number &&
        other.url == url &&
        other.type == type;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        nameMessage.hashCode ^
        number.hashCode ^
        url.hashCode ^
        type.hashCode;
  }
}