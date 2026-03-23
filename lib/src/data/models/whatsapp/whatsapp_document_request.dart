class WhatsappDocumentRequest {
  final String number;
  final String filename;
  final String document;

  const WhatsappDocumentRequest({
    required this.number,
    required this.filename,
    required this.document,
  });

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'filename': filename,
      'document': document,
    };
  }

  factory WhatsappDocumentRequest.fromJson(Map<String, dynamic> json) {
    return WhatsappDocumentRequest(
      number: json['number'] ?? '',
      filename: json['filename'] ?? '',
      document: json['document'] ?? '',
    );
  }

  WhatsappDocumentRequest copyWith({
    String? number,
    String? filename,
    String? document,
  }) {
    return WhatsappDocumentRequest(
      number: number ?? this.number,
      filename: filename ?? this.filename,
      document: document ?? this.document,
    );
  }

  @override
  String toString() {
    return 'WhatsappDocumentRequest(number: $number, filename: $filename, document: $document)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WhatsappDocumentRequest &&
        other.number == number &&
        other.filename == filename &&
        other.document == document;
  }

  @override
  int get hashCode => number.hashCode ^ filename.hashCode ^ document.hashCode;
}