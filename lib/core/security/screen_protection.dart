import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ScreenProtection extends ChangeNotifier {
  static const String _captureChanged = 'captureChanged';
  static const String _isCapturedMethod = 'isCaptured';

  static const MethodChannel _channel = MethodChannel('salli/screen_protection');

  bool _isCaptured = false;

  bool get isCaptured => _isCaptured;

  Future<void> start() async {
    _channel.setMethodCallHandler(_handle);
    try {
      _update(await _channel.invokeMethod<bool>(_isCapturedMethod) ?? false);
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  Future<void> _handle(MethodCall call) async {
    if (call.method == _captureChanged) _update(call.arguments == true);
  }

  void _update(bool isCaptured) {
    if (isCaptured == _isCaptured) return;
    _isCaptured = isCaptured;
    notifyListeners();
  }
}
