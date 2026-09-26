import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  final FlutterSecureStorage _storage;

  const SecureStore(this._storage);

  SecureStore.device()
    : this(
        const FlutterSecureStorage(
          aOptions: AndroidOptions(migrateWithBackup: false),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
        ),
      );

  Future<void> clear() => _storage.deleteAll();

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
}
