import 'package:flutter/foundation.dart';

import '../storage/secure_keys.dart';
import '../storage/secure_store.dart';
import '../utils/id_generator.dart';
import 'device_key_store.dart';
import 'device_registration.dart';

class DeviceIdentity {
  static const String keyAlias = 'salli.device';

  final DeviceKeyStore _keyStore;

  final SecureStore _secureStore;

  String? _id;

  DeviceIdentity(this._keyStore, this._secureStore);

  Future<DeviceRegistration> prepare() async {
    final id = await currentId() ?? await _createId();
    final publicKey = await _keyStore.publicKey(keyAlias) ?? await _keyStore.generate(keyAlias);
    return DeviceRegistration(id: id, platform: defaultTargetPlatform.name.toLowerCase(), publicKey: publicKey);
  }

  Future<String> sign(List<int> payload) => _keyStore.sign(keyAlias, payload);

  Future<String?> currentId() async => _id ??= await _secureStore.read(SecureKeys.deviceId);

  Future<String> _createId() async {
    final id = IdGenerator.next();
    await _secureStore.write(SecureKeys.deviceId, id);
    return _id = id;
  }
}
