import 'authorization.dart';
import 'biometric_vault.dart';
import 'pin_credential.dart';

class Approver {
  static const String biometricMethod = 'biometric';
  static const String pinMethod = 'pin';

  final BiometricVault _biometricVault;

  final PinCredential _pinCredential;

  const Approver(this._biometricVault, this._pinCredential);

  Future<Map<String, dynamic>> approve(Authorization authorization, List<int> payload) async => switch (authorization) {
    PinAuthorization(:final pin) => {'method': pinMethod, 'pinHash': await _pinCredential.hash(pin)},
    BiometricAuthorization(:final prompt) => {'method': biometricMethod, 'signature': await _biometricVault.sign(payload, prompt)},
  };
}
