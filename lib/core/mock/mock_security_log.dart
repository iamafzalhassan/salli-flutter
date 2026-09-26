import '../utils/id_generator.dart';
import 'mock_collections.dart';
import 'mock_store.dart';

class MockSecurityLog {
  static const String accountCreated = 'account_created';
  static const String biometricsDisabled = 'biometrics_disabled';
  static const String biometricsEnabled = 'biometrics_enabled';
  static const String cardFrozen = 'card_frozen';
  static const String cardLimitChanged = 'card_limit_changed';
  static const String cardUnfrozen = 'card_unfrozen';
  static const String newDevice = 'new_device';
  static const String pinChanged = 'pin_changed';
  static const String pinReset = 'pin_reset';
  static const String signedIn = 'signed_in';

  final DateTime Function() _clock;

  final MockStore _store;

  MockSecurityLog(this._store, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  Future<void> record(String userId, String kind, {String? platform}) async {
    final id = IdGenerator.next();
    await _store.put(MockCollections.securityEvents, id, {'id': id, 'kind': kind, 'platform': platform, 'userId': userId, 'createdAt': _clock().toUtc().toIso8601String()});
  }
}
