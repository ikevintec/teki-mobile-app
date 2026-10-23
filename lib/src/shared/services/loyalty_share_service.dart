import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

final loyaltyShareServiceProvider = Provider((ref) => LoyaltyShareService());

class LoyaltyShareService {
  Future<void> copy(String url) => Clipboard.setData(ClipboardData(text: url));

  Future<void> share(String message, Rect origin) async {
    await SharePlus.instance.share(
      ShareParams(text: message, sharePositionOrigin: origin),
    );
  }
}
