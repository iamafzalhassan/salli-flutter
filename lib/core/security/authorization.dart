import 'biometric_prompt_text.dart';

sealed class Authorization {
  const Authorization();
}

final class PinAuthorization extends Authorization {
  final String pin;

  const PinAuthorization(this.pin);
}

final class BiometricAuthorization extends Authorization {
  final BiometricPromptText prompt;

  const BiometricAuthorization(this.prompt);
}
