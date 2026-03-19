enum EscPosOrderType { TEXT, FEED, IMAGE, QR, DRAWER }

class EscPosStyle {
  final String? fontSize;
  final String? fontSizeX;
  final String? fontSizeY;
  final bool? bold;
  final String? justification;

  const EscPosStyle({
    this.fontSize,
    this.fontSizeX,
    this.fontSizeY,
    this.bold,
    this.justification,
  });

  Map<String, dynamic> toJson() => {
        if (fontSize != null) 'fontSize': fontSize,
        if (fontSizeX != null) 'fontSizeX': fontSizeX,
        if (fontSizeY != null) 'fontSizeY': fontSizeY,
        if (bold != null) 'bold': bold,
        if (justification != null) 'justification': justification,
      };
}

class EscPosOrderText {
  final String? value;
  final bool? lineBreak;
  final EscPosStyle? style;

  const EscPosOrderText({this.value, this.lineBreak, this.style});

  Map<String, dynamic> toJson() => {
        if (value != null) 'value': value,
        if (lineBreak != null) 'lineBreak': lineBreak,
        if (style != null) 'style': style!.toJson(),
      };
}

class EscPosOrderImage {
  final String? url;
  final String? justification;
  final int? width;

  const EscPosOrderImage({this.url, this.justification, this.width});

  Map<String, dynamic> toJson() => {
        if (url != null) 'url': url,
        if (justification != null) 'justification': justification,
        if (width != null) 'width': width,
      };
}

class EscPosOrderQr {
  final String? value;
  final String? justification;
  final int? size;

  const EscPosOrderQr({this.value, this.justification, this.size});

  Map<String, dynamic> toJson() => {
        if (value != null) 'value': value,
        if (justification != null) 'justification': justification,
        if (size != null) 'size': size,
      };
}

class EscPosOrder {
  final EscPosOrderType? type;
  final EscPosOrderText? text;
  final EscPosOrderImage? image;
  final EscPosOrderQr? qr;
  final int? feed;

  const EscPosOrder({this.type, this.text, this.image, this.qr, this.feed});

  Map<String, dynamic> toJson() => {
        if (type != null) 'type': type!.name,
        if (text != null) 'text': text!.toJson(),
        if (image != null) 'image': image!.toJson(),
        if (qr != null) 'qr': qr!.toJson(),
        if (feed != null) 'feed': feed,
      };
}
