import 'mock_collections.dart';
import 'mock_limits.dart';
import 'mock_notifier.dart';
import 'mock_store.dart';

class MockKycReviewer {
  static const String notStarted = 'not_started';
  static const String pending = 'pending';
  static const String rejected = 'rejected';
  static const String reviewFailedReason = 'review_failed';
  static const String unclearDocumentSuffix = '0000';
  static const String unclearReason = 'document_unclear';
  static const String verified = 'verified';

  static const Duration reviewDelay = Duration(seconds: 20);

  final DateTime Function() _clock;

  final MockNotifier _notifier;

  final MockStore _store;

  MockKycReviewer(this._notifier, this._store, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  Future<Map<String, dynamic>?> settle(String userId) async {
    final user = _store.find(MockCollections.users, userId);
    if (user == null || user['kycStatus'] != pending) return user;
    final now = _clock().toUtc();
    if (now.difference(DateTime.parse(user['kycSubmittedAt'] as String)) < reviewDelay) return user;
    final nic = user['nic'] as String;
    final isDuplicate = _store.all(MockCollections.users).any((other) => other['id'] != userId && other['nic'] == nic && other['kycStatus'] == verified);
    final reason = isDuplicate ? reviewFailedReason : (nic.endsWith(unclearDocumentSuffix) ? unclearReason : null);
    final reviewed = {...user, 'kycRejectionReason': reason, 'kycReviewedAt': now.toIso8601String(), 'kycStatus': reason == null ? verified : rejected, 'kycTier': reason == null ? MockLimits.verifiedTier : MockLimits.basicTier};
    await _store.put(MockCollections.users, userId, reviewed);
    await _notifier.notify(userId, reason == null ? MockNotifier.kycVerified : MockNotifier.kycRejected, params: {'reason': ?reason});
    return reviewed;
  }
}
