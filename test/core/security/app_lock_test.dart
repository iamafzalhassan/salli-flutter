import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/security/app_lock.dart';
import 'package:salli/core/security/session.dart';
import 'package:salli/core/security/session_store.dart';

import '../../helpers/memory_secure_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final session = Session(accessExpiresAt: DateTime.utc(2030), accessToken: 'access', refreshToken: 'refresh', userId: 'user');

  late DateTime now;
  late SessionStore sessionStore;

  Future<AppLock> lockWith({required bool isSignedIn}) async {
    sessionStore = SessionStore(MemorySecureStore());
    if (isSignedIn) await sessionStore.save(session);
    return AppLock(sessionStore, clock: () => now);
  }

  void background(AppLock lock, Duration duration) {
    lock.didChangeAppLifecycleState(AppLifecycleState.paused);
    now = now.add(duration);
    lock.didChangeAppLifecycleState(AppLifecycleState.resumed);
  }

  setUp(() => now = DateTime.utc(2026, 9, 21, 10));

  test('a signed-in app starts locked', () async => expect((await lockWith(isSignedIn: true)).isLocked, isTrue));

  test('a signed-out app is never locked', () async => expect((await lockWith(isSignedIn: false)).isLocked, isFalse));

  test('unlocking notifies listeners once', () async {
    final lock = await lockWith(isSignedIn: true);
    var notifications = 0;
    lock
      ..addListener(() => notifications++)
      ..unlock()
      ..unlock();
    expect(lock.isLocked, isFalse);
    expect(notifications, 1);
  });

  test('a short trip to the background stays unlocked', () async {
    final lock = await lockWith(isSignedIn: true)
      ..unlock();
    background(lock, AppLock.timeout - const Duration(seconds: 1));
    expect(lock.isLocked, isFalse);
  });

  test('a minute in the background locks the app', () async {
    final lock = await lockWith(isSignedIn: true)
      ..unlock();
    background(lock, AppLock.timeout);
    expect(lock.isLocked, isTrue);
  });

  test('signing out clears the lock', () async {
    final lock = await lockWith(isSignedIn: true);
    await sessionStore.clear();
    expect(lock.isLocked, isFalse);
  });
}
