import 'dart:convert';

import 'package:hive_ce/hive_ce.dart';

import 'secure_keys.dart';
import 'secure_store.dart';

class LocalDatabase {
  static const String mockApiBox = 'mock_api';

  final SecureStore _secureStore;

  Future<List<int>>? _key;

  LocalDatabase(this._secureStore);

  Future<Box<String>> open(String name) async => Hive.openBox<String>(name, encryptionCipher: HiveAesCipher(await (_key ??= _encryptionKey())));

  Future<List<int>> _encryptionKey() async {
    final stored = await _secureStore.read(SecureKeys.databaseKey);
    if (stored != null) return base64Url.decode(stored);
    final key = Hive.generateSecureKey();
    await _secureStore.write(SecureKeys.databaseKey, base64UrlEncode(key));
    return key;
  }
}
