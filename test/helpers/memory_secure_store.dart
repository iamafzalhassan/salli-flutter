import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:salli/core/storage/secure_store.dart';

class MemorySecureStore extends SecureStore {
  final Map<String, String> values = {};

  MemorySecureStore() : super(const FlutterSecureStorage());

  @override
  Future<void> clear() async => values.clear();

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
