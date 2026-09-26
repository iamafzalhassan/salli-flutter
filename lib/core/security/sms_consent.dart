import 'package:flutter/services.dart';

class SmsConsent {
  static const String _cancelMethod = 'cancel';
  static const String _listenMethod = 'listen';

  static const MethodChannel _channel = MethodChannel('salli/sms_consent');

  const SmsConsent();

  Future<void> cancel() async {
    try {
      await _channel.invokeMethod<void>(_cancelMethod);
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  Future<String?> listenForCode(int length) async {
    try {
      final message = await _channel.invokeMethod<String>(_listenMethod);
      return message == null ? null : codeIn(message, length);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  static String? codeIn(String message, int length) => RegExp('(?<!\\d)(\\d{$length})(?!\\d)').firstMatch(message)?.group(1);
}
