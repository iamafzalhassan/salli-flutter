import 'dart:convert';

import 'package:flutter/services.dart';

class DeviceKeyStore {
  static const MethodChannel _channel = MethodChannel('salli/device_keys');

  const DeviceKeyStore();

  Future<void> delete(String alias) => _channel.invokeMethod<void>('delete', {'alias': alias});

  Future<String> generate(String alias) async => (await _channel.invokeMethod<String>('generate', {'alias': alias}))!;

  Future<String?> publicKey(String alias) => _channel.invokeMethod<String>('publicKey', {'alias': alias});

  Future<String> sign(String alias, List<int> payload) async => (await _channel.invokeMethod<String>('sign', {'alias': alias, 'payload': base64Encode(payload)}))!;
}
