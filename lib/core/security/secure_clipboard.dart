import 'dart:async';

import 'package:flutter/services.dart';

abstract final class SecureClipboard {
  static const Duration lifetime = Duration(seconds: 60);

  static Timer? _expiry;

  static Future<void> copy(String text) async {
    _expiry?.cancel();
    await Clipboard.setData(ClipboardData(text: text));
    _expiry = Timer(lifetime, () => unawaited(_clearIfUnchanged(text)));
  }

  static Future<void> _clearIfUnchanged(String text) async {
    final current = await Clipboard.getData(Clipboard.kTextPlain);
    if (current?.text == text) await Clipboard.setData(const ClipboardData(text: ''));
  }
}
