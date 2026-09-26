import '../utils/id_generator.dart';
import 'mock_collections.dart';
import 'mock_store.dart';

class MockNotifier {
  static const String cashbackEarned = 'cashback_earned';
  static const String kycRejected = 'kyc_rejected';
  static const String kycVerified = 'kyc_verified';
  static const String moneyReceived = 'money_received';
  static const String referralJoined = 'referral_joined';
  static const String requestPaid = 'request_paid';
  static const String requestReceived = 'request_received';
  static const String scratchCardEarned = 'scratch_card_earned';
  static const String welcome = 'welcome';

  final DateTime Function() _clock;

  final MockStore _store;

  MockNotifier(this._store, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  Future<void> notify(String userId, String kind, {Map<String, Object?> params = const {}}) async {
    final id = IdGenerator.next();
    await _store.put(MockCollections.notifications, id, {'id': id, 'isRead': false, 'kind': kind, 'params': params, 'userId': userId, 'createdAt': _clock().toUtc().toIso8601String()});
  }
}
