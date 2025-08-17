class WhatsappMessageRequest {
  final String number;
  final String message;

  const WhatsappMessageRequest({
    required this.number,
    required this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'message': message,
    };
  }

  factory WhatsappMessageRequest.fromJson(Map<String, dynamic> json) {
    return WhatsappMessageRequest(
      number: json['number'] ?? '',
      message: json['message'] ?? '',
    );
  }

  WhatsappMessageRequest copyWith({
    String? number,
    String? message,
  }) {
    return WhatsappMessageRequest(
      number: number ?? this.number,
      message: message ?? this.message,
    );
  }

  @override
  String toString() {
    return 'WhatsappMessageRequest(number: $number, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WhatsappMessageRequest &&
        other.number == number &&
        other.message == message;
  }

  @override
  int get hashCode => number.hashCode ^ message.hashCode;
}