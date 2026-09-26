import 'dart:io';

import 'package:hive_ce/hive_ce.dart';
import 'package:salli/core/mock/mock_ledger.dart';
import 'package:salli/core/mock/mock_modules.dart';
import 'package:salli/core/mock/mock_request.dart';
import 'package:salli/core/mock/mock_response.dart';
import 'package:salli/core/mock/mock_server.dart';
import 'package:salli/core/mock/mock_sms_inbox.dart';
import 'package:salli/core/mock/mock_store.dart';
import 'package:salli/core/mock/mock_wallet_seeder.dart';
import 'package:salli/core/network/api_headers.dart';
import 'package:salli/core/network/api_paths.dart';
import 'package:salli/core/security/approval_payload.dart';
import 'package:salli/core/security/approver.dart';
import 'package:salli/core/security/request_canonicalizer.dart';
import 'package:salli/core/utils/id_generator.dart';

import 'test_device_key.dart';

class MockApiHarness {
  static const String deviceId = 'device-1';
  static const String phone = '+94771234567';

  final TestDeviceKey deviceKey = TestDeviceKey.generate(7);

  late DateTime now;

  late Directory _directory;

  late MockServer server;

  late MockSmsInbox inbox;

  late MockStore store;

  String get deliveredCode => RegExp(r'\d{6}').firstMatch(inbox.value!.body)!.group(0)!;

  Map<String, dynamic> get device => {'id': deviceId, 'platform': 'android', 'publicKey': deviceKey.publicKey};

  Future<MockResponse> authorized(String method, String path, Map<String, dynamic> session, {Map<String, dynamic>? body, Map<String, dynamic> headers = const {}, Map<String, dynamic> query = const {}}) =>
      send(method, path, accessToken: session['accessToken'] as String, body: body, headers: headers, isSigned: true, query: query);

  static String? errorCode(MockResponse response) => (response.body['error'] as Map<String, dynamic>?)?['code'] as String?;

  static String? errorField(MockResponse response) => (response.body['error'] as Map<String, dynamic>?)?['field'] as String?;

  Future<void> fund(Map<String, dynamic> session, int amountCents) => MockLedger(store)
      .post(amountCents: amountCents, at: now, creditAccount: MockWalletSeeder.walletAccount((session['user'] as Map<String, dynamic>)['id'] as String), creditName: phone, debitAccount: 'external:test', debitName: 'Test', type: 'top_up');

  Future<Map<String, dynamic>> login({String pinHash = 'hash-a', String phone = phone}) async {
    final verification = await verify(phone: phone);
    return (await send('POST', ApiPaths.login, body: {'device': device, 'pinHash': pinHash, 'registrationToken': verification['registrationToken']})).body;
  }

  Future<Map<String, dynamic>> register({String pinHash = 'hash-a', String phone = phone}) async {
    final verification = await verify(phone: phone);
    return (await send('POST', ApiPaths.register, body: {'device': device, 'pinHash': pinHash, 'registrationToken': verification['registrationToken']})).body;
  }

  Future<void> setUp() async {
    now = DateTime.utc(2026, 9, 21, 10);
    _directory = await Directory.systemTemp.createTemp('salli_mock_api');
    Hive.init(_directory.path);
    inbox = MockSmsInbox();
    store = MockStore(await Hive.openBox<String>('mock_api'));
    server = MockServer(mockModules(inbox, store, clock: () => now), store);
  }

  Future<void> tearDown() async {
    await Hive.close();
    await _directory.delete(recursive: true);
  }

  Map<String, dynamic> unlockApproval({String? pinHash, TestDeviceKey? biometricKey, String? nonce}) {
    final unlockNonce = nonce ?? IdGenerator.next();
    final timestamp = '${now.millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond}';
    final approval = biometricKey == null ? {'method': Approver.pinMethod, 'pinHash': pinHash} : {'method': Approver.biometricMethod, 'signature': biometricKey.sign(ApprovalPayload.unlock(nonce: unlockNonce, timestamp: timestamp))};
    return {...approval, 'nonce': unlockNonce, 'timestamp': timestamp};
  }

  Future<Map<String, dynamic>> verify({String phone = phone}) async {
    final challenge = await send('POST', ApiPaths.otp, body: {'phone': phone});
    return (await send('POST', ApiPaths.otpVerify, body: {'challengeId': challenge.body['challengeId'], 'code': deliveredCode})).body;
  }

  Future<MockResponse> send(
    String method,
    String path, {
    String? accessToken,
    bool isSigned = false,
    String? nonce,
    Duration signingSkew = Duration.zero,
    Map<String, dynamic>? body,
    Map<String, dynamic> headers = const {},
    Map<String, dynamic> query = const {},
    TestDeviceKey? signingKey,
  }) {
    final allHeaders = <String, dynamic>{
      ...headers,
      if (accessToken != null) ApiHeaders.authorization: 'Bearer $accessToken',
      if (isSigned) ...(signingKey ?? deviceKey).signedHeaders(body: body, deviceId: deviceId, method: method, nonce: nonce ?? IdGenerator.next(), path: path, query: query, signedAt: now.add(signingSkew)),
    };
    return server.handle(MockRequest(body: body ?? const {}, headers: allHeaders, method: method, path: path, query: query, rawBody: RequestCanonicalizer.bodyOf(body)));
  }
}
