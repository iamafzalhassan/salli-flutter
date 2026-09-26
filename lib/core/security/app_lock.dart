import 'package:flutter/widgets.dart';

import 'session_store.dart';

class AppLock extends ChangeNotifier with WidgetsBindingObserver {
  static const Duration timeout = Duration(seconds: 60);

  final DateTime Function() _clock;

  final SessionStore _sessionStore;

  bool _isLocked;

  DateTime? _backgroundedAt;

  AppLock(this._sessionStore, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now, _isLocked = _sessionStore.isSignedIn {
    WidgetsBinding.instance.addObserver(this);
    _sessionStore.addListener(_onSessionChanged);
  }

  bool get isLocked => _isLocked && _sessionStore.isSignedIn;

  void unlock() {
    if (!_isLocked) return;
    _isLocked = false;
    notifyListeners();
  }

  void _onSessionChanged() {
    if (!_sessionStore.isSignedIn) _isLocked = false;
  }

  void _lock() {
    _isLocked = true;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionStore.removeListener(_onSessionChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        _backgroundedAt ??= _clock();
      case AppLifecycleState.resumed:
        final backgroundedAt = _backgroundedAt;
        _backgroundedAt = null;
        if (backgroundedAt != null && _sessionStore.isSignedIn && _clock().difference(backgroundedAt) >= timeout) _lock();
      case AppLifecycleState.detached || AppLifecycleState.inactive:
        return;
    }
  }
}
