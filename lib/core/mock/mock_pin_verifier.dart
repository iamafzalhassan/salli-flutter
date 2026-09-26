import 'dart:convert';
import 'dart:math';

import '../errors/failure_codes.dart';
import 'mock_collections.dart';
import 'mock_response.dart';
import 'mock_store.dart';

class MockPinVerifier {
  static const int maxAttempts = 5;

  static const Duration lockout = Duration(minutes: 30);

  final DateTime Function() _clock;

  final MockStore _store;

  MockPinVerifier(this._store, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  Future<MockResponse?> verify(String userId, Object? pinHash) async {
    final user = _store.find(MockCollections.users, userId);
    if (user == null) return MockResponse.error(401, FailureCodes.unauthorized);
    final now = _clock().toUtc();
    final lockedUntil = user['pinLockedUntil'] as String?;
    if (lockedUntil != null && now.isBefore(DateTime.parse(lockedUntil))) return MockResponse.error(403, FailureCodes.pinLocked);
    if (pinHash is String && matches(pinHash, user['pinHash'] as String)) {
      await _store.put(MockCollections.users, userId, {...user, 'pinAttempts': 0, 'pinLockedUntil': null});
      return null;
    }
    final attempts = (user['pinAttempts'] as int) + 1;
    final isLocked = attempts >= maxAttempts;
    await _store.put(MockCollections.users, userId, {...user, 'pinAttempts': isLocked ? 0 : attempts, 'pinLockedUntil': isLocked ? now.add(lockout).toIso8601String() : null});
    return isLocked ? MockResponse.error(403, FailureCodes.pinLocked) : MockResponse.error(401, FailureCodes.pinInvalid, field: 'pinHash');
  }

  static bool matches(String candidate, String expected) {
    final left = utf8.encode(candidate);
    final right = utf8.encode(expected);
    var difference = left.length ^ right.length;
    for (var index = 0; index < min(left.length, right.length); index++) {
      difference |= left[index] ^ right[index];
    }
    return difference == 0;
  }
}
