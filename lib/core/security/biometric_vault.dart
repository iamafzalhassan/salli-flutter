import '../errors/failure_codes.dart';
import '../network/api_exception.dart';
import '../storage/secure_keys.dart';
import '../storage/secure_store.dart';
import 'biometric_availability.dart';
import 'biometric_key_store.dart';
import 'biometric_prompt_text.dart';

class BiometricVault {
  static const String _enabled = 'true';
  static const String keyAlias = 'salli.biometric';

  final BiometricKeyStore _keyStore;

  final SecureStore _secureStore;

  const BiometricVault(this._keyStore, this._secureStore);

  Future<BiometricAvailability> availability() => _keyStore.availability();

  Future<String> createKey() => _keyStore.generate(keyAlias);

  Future<bool> isEnabled() async => await _secureStore.read(SecureKeys.biometricEnabled) == _enabled;

  Future<void> markEnabled() => _secureStore.write(SecureKeys.biometricEnabled, _enabled);

  Future<String> sign(List<int> payload, BiometricPromptText prompt) async {
    try {
      return await _keyStore.sign(keyAlias, payload, prompt);
    } on ApiException catch (exception) {
      if (exception.failure.code == FailureCodes.biometricInvalidated) await reset();
      rethrow;
    }
  }

  Future<void> reset() async {
    await _secureStore.delete(SecureKeys.biometricEnabled);
    await _keyStore.delete(keyAlias);
  }
}
