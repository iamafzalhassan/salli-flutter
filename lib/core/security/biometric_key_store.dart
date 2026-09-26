import 'dart:convert';

import 'package:flutter/services.dart';

import '../errors/failure.dart';
import '../errors/failure_codes.dart';
import '../network/api_exception.dart';
import 'biometric_availability.dart';
import 'biometric_prompt_text.dart';

class BiometricKeyStore {
  static const Map<String, String> _failureCodes = {'cancelled': FailureCodes.biometricCancelled, 'invalidated': FailureCodes.biometricInvalidated, 'lockout': FailureCodes.biometricLockout};

  static const MethodChannel _channel = MethodChannel('salli/biometric_keys');

  const BiometricKeyStore();

  Future<BiometricAvailability> availability() async {
    try {
      return BiometricAvailability.values.asNameMap()[await _channel.invokeMethod<String>('availability')] ?? BiometricAvailability.unavailable;
    } on PlatformException {
      return BiometricAvailability.unavailable;
    }
  }

  Future<void> delete(String alias) => _channel.invokeMethod<void>('delete', {'alias': alias});

  Future<String> generate(String alias) async => (await _channel.invokeMethod<String>('generate', {'alias': alias}))!;

  Future<String> sign(String alias, List<int> payload, BiometricPromptText prompt) async {
    try {
      return (await _channel.invokeMethod<String>('sign', {'alias': alias, 'cancel': prompt.cancel, 'payload': base64Encode(payload), 'title': prompt.title}))!;
    } on PlatformException catch (exception) {
      throw ApiException(failure: Failure(_failureCodes[exception.code] ?? FailureCodes.biometricUnavailable));
    }
  }
}
