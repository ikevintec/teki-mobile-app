class WhatsappEvolutionMediaRequest {
  final String number;
  final String media;
  final String caption;
  final String fileName;
  final String mediatype;

  const WhatsappEvolutionMediaRequest({
    required this.number,
    required this.media,
    required this.caption,
    required this.fileName,
    this.mediatype = 'document',
  });

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'media': media,
      'caption': caption,
      'fileName': fileName,
      'mediatype': mediatype,
    };
  }

  factory WhatsappEvolutionMediaRequest.fromJson(Map<String, dynamic> json) {
    return WhatsappEvolutionMediaRequest(
      number: json['number'] ?? '',
      media: json['media'] ?? '',
      caption: json['caption'] ?? '',
      fileName: json['fileName'] ?? '',
      mediatype: json['mediatype'] ?? 'document',
    );
  }

  WhatsappEvolutionMediaRequest copyWith({
    String? number,
    String? media,
    String? caption,
    String? fileName,
    String? mediatype,
  }) {
    return WhatsappEvolutionMediaRequest(
      number: number ?? this.number,
      media: media ?? this.media,
      caption: caption ?? this.caption,
      fileName: fileName ?? this.fileName,
      mediatype: mediatype ?? this.mediatype,
    );
  }

  @override
  String toString() {
    return 'WhatsappEvolutionMediaRequest(number: $number, media: $media, caption: $caption, fileName: $fileName, mediatype: $mediatype)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WhatsappEvolutionMediaRequest &&
        other.number == number &&
        other.media == media &&
        other.caption == caption &&
        other.fileName == fileName &&
        other.mediatype == mediatype;
  }

  @override
  int get hashCode {
    return number.hashCode ^
        media.hashCode ^
        caption.hashCode ^
        fileName.hashCode ^
        mediatype.hashCode;
  }
}