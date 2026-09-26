import '../errors/failure.dart';
import '../errors/failure_codes.dart';
import '../network/api_exception.dart';
import '../storage/secure_keys.dart';
import '../storage/secure_store.dart';
import 'pin_hasher.dart';

class PinCredential {
  final PinHasher _pinHasher;

  final SecureStore _secureStore;

  const PinCredential(this._pinHasher, this._secureStore);

  Future<void> clear() => _secureStore.delete(SecureKeys.pinSalt);

  Future<String> hash(String pin) async {
    final salt = await _secureStore.read(SecureKeys.pinSalt);
    if (salt == null) throw const ApiException(failure: Failure(FailureCodes.unauthorized));
    return _pinHasher.hash(pin, salt);
  }

  Future<void> remember(String salt) => _secureStore.write(SecureKeys.pinSalt, salt);
}
