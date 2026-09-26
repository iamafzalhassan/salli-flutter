import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/security/runtime_guard.dart';
import 'package:salli/core/security/runtime_threat.dart';
import 'package:salli/core/security/session.dart';
import 'package:salli/core/security/session_store.dart';

import '../../helpers/memory_secure_store.dart';

void main() {
  late SessionStore sessionStore;

  setUp(() async {
    sessionStore = SessionStore(MemorySecureStore());
    await sessionStore.save(Session(accessExpiresAt: DateTime.utc(2030), accessToken: 'access', refreshToken: 'refresh', userId: 'user'));
  });

  test('an emulator pauses money actions but keeps the session', () async {
    final guard = RuntimeGuard(sessionStore);
    var notifications = 0;
    guard
      ..addListener(() => notifications++)
      ..detect(RuntimeThreat.emulator)
      ..detect(RuntimeThreat.emulator);
    await Future<void>.delayed(Duration.zero);
    expect(guard.isCompromised, isTrue);
    expect(guard.threats, {RuntimeThreat.emulator});
    expect(notifications, 1);
    expect(sessionStore.isSignedIn, isTrue);
  });

  test('hooking or tampering also signs the user out', () async {
    RuntimeGuard(sessionStore).detect(RuntimeThreat.hooking);
    await Future<void>.delayed(Duration.zero);
    expect(sessionStore.isSignedIn, isFalse);
  });
}
