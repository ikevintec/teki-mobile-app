class WhatsappSocketRequest {
  final String event;
  final int idCompany;
  final String number;
  final String message;
  final String file;
  final String url;

  const WhatsappSocketRequest({
    required this.event,
    required this.idCompany,
    required this.number,
    required this.message,
    required this.file,
    required this.url,
  });

  Map<String, dynamic> toJson() {
    return {
      'event': event,
      'idCompany': idCompany,
      'number': number,
      'message': message,
      'file': file,
      'url': url,
    };
  }

  factory WhatsappSocketRequest.fromJson(Map<String, dynamic> json) {
    return WhatsappSocketRequest(
      event: json['event'] ?? '',
      idCompany: json['idCompany'] ?? 0,
      number: json['number'] ?? '',
      message: json['message'] ?? '',
      file: json['file'] ?? '',
      url: json['url'] ?? '',
    );
  }

  WhatsappSocketRequest copyWith({
    String? event,
    int? idCompany,
    String? number,
    String? message,
    String? file,
    String? url,
  }) {
    return WhatsappSocketRequest(
      event: event ?? this.event,
      idCompany: idCompany ?? this.idCompany,
      number: number ?? this.number,
      message: message ?? this.message,
      file: file ?? this.file,
      url: url ?? this.url,
    );
  }

  @override
  String toString() {
    return 'WhatsappSocketRequest(event: $event, idCompany: $idCompany, number: $number, message: $message, file: $file, url: $url)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WhatsappSocketRequest &&
        other.event == event &&
        other.idCompany == idCompany &&
        other.number == number &&
        other.message == message &&
        other.file == file &&
        other.url == url;
  }

  @override
  int get hashCode {
    return event.hashCode ^
        idCompany.hashCode ^
        number.hashCode ^
        message.hashCode ^
        file.hashCode ^
        url.hashCode;
  }
}