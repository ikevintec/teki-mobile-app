class WhatsappResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;

  const WhatsappResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory WhatsappResponse.fromJson(Map<String, dynamic> json) {
    return WhatsappResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
    };
  }

  WhatsappResponse copyWith({
    bool? success,
    String? message,
    Map<String, dynamic>? data,
  }) {
    return WhatsappResponse(
      success: success ?? this.success,
      message: message ?? this.message,
      data: data ?? this.data,
    );
  }

  @override
  String toString() {
    return 'WhatsappResponse(success: $success, message: $message, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WhatsappResponse &&
        other.success == success &&
        other.message == message &&
        other.data == data;
  }

  @override
  int get hashCode => success.hashCode ^ message.hashCode ^ data.hashCode;
}