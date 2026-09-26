import 'package:flutter/foundation.dart';

import '../storage/secure_keys.dart';
import '../storage/secure_store.dart';
import 'session.dart';
import 'session_codec.dart';

class SessionStore extends ChangeNotifier {
  final SecureStore _secureStore;

  Session? _current;

  SessionStore(this._secureStore);

  bool get isSignedIn => _current != null;

  Session? get current => _current;

  Future<void> clear() async {
    if (_current == null) return;
    _current = null;
    await _secureStore.delete(SecureKeys.session);
    notifyListeners();
  }

  Future<void> load() async {
    final raw = await _secureStore.read(SecureKeys.session);
    _current = raw == null ? null : SessionCodec.fromStorage(raw);
  }

  Future<void> save(Session session) async {
    await _secureStore.write(SecureKeys.session, SessionCodec.toStorage(session));
    _current = session;
    notifyListeners();
  }
}
