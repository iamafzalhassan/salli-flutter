import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

class NetworkStatus extends ChangeNotifier {
  static const Duration probeInterval = Duration(seconds: 10);

  final Future<bool> Function() _probe;

  bool _isOffline = false;

  Timer? _probeTimer;

  NetworkStatus(this._probe);

  bool get isOffline => _isOffline;

  static Future<bool> canReach(String host) async {
    try {
      return (await InternetAddress.lookup(host)).isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  void markOffline() {
    if (_isOffline) return;
    _isOffline = true;
    _probeTimer = Timer.periodic(probeInterval, (_) => unawaited(_check()));
    notifyListeners();
  }

  void markOnline() {
    _probeTimer?.cancel();
    _probeTimer = null;
    if (!_isOffline) return;
    _isOffline = false;
    notifyListeners();
  }

  Future<void> _check() async {
    if (await _probe()) markOnline();
  }

  @override
  void dispose() {
    _probeTimer?.cancel();
    super.dispose();
  }
}
