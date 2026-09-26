import 'dart:convert';
import 'dart:math';

import '../../errors/failure_codes.dart';
import '../../network/api_paths.dart';
import '../../security/approval_payload.dart';
import '../../utils/id_generator.dart';
import '../../utils/nic.dart';
import '../mock_approval_verifier.dart';
import '../mock_authenticator.dart';
import '../mock_collections.dart';
import '../mock_module.dart';
import '../mock_pin_verifier.dart';
import '../mock_request.dart';
import '../mock_response.dart';
import '../mock_route.dart';
import '../mock_security_log.dart';
import '../mock_sms_inbox.dart';
import '../mock_store.dart';

class AuthMockModule implements MockModule {
  static const int codeLength = 6;
  static const int maxOtpAttempts = 5;
  static const int publicKeyLength = 65;
  static const int saltLength = 16;
  static const int uncompressedPointPrefix = 4;

  static const Set<String> _platforms = {'android', 'ios'};

  static const Duration otpLifetime = Duration(minutes: 3);
  static const Duration registrationLifetime = Duration(minutes: 10);
  static const Duration resendDelay = Duration(seconds: 30);

  static final RegExp _phonePattern = RegExp(r'^\+947[0124-8]\d{7}$');

  final DateTime Function() _clock;

  final MockApprovalVerifier _approvalVerifier;

  final MockAuthenticator _authenticator;

  final MockPinVerifier _pinVerifier;

  final MockSecurityLog _securityLog;

  final MockSmsInbox _inbox;

  final MockStore _store;

  final Random _random = Random.secure();

  AuthMockModule(this._approvalVerifier, this._authenticator, this._pinVerifier, this._securityLog, this._inbox, this._store, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  Future<MockResponse> _requestOtp(MockRequest request) async {
    final phone = request.body['phone'];
    if (phone is! String || !_phonePattern.hasMatch(phone)) return MockResponse.error(400, FailureCodes.invalidPhone, field: 'phone');
    final now = _clock().toUtc();
    final throttle = _store.find(MockCollections.throttles, phone);
    if (throttle != null && now.isBefore(DateTime.parse(throttle['resendAvailableAt'] as String))) return MockResponse.error(429, FailureCodes.otpRateLimited);
    if (throttle != null) await _store.remove(MockCollections.challenges, throttle['challengeId'] as String);
    final challengeId = IdGenerator.next();
    final code = [for (var index = 0; index < codeLength; index++) _random.nextInt(10)].join();
    final expiresAt = now.add(otpLifetime).toIso8601String();
    final resendAvailableAt = now.add(resendDelay).toIso8601String();
    await _store.put(MockCollections.challenges, challengeId, {'attempts': 0, 'code': code, 'phone': phone, 'expiresAt': expiresAt});
    await _store.put(MockCollections.throttles, phone, {'challengeId': challengeId, 'resendAvailableAt': resendAvailableAt});
    _inbox.deliver('Your Salli code is $code. It expires in ${otpLifetime.inMinutes} minutes. Never share it with anyone, not even Salli staff.');
    return MockResponse.created({'codeLength': codeLength, 'challengeId': challengeId, 'expiresAt': expiresAt, 'resendAvailableAt': resendAvailableAt});
  }

  Future<MockResponse> _verifyOtp(MockRequest request) async {
    final challengeId = request.body['challengeId'];
    final code = request.body['code'];
    if (challengeId is! String || code is! String) return MockResponse.error(400, FailureCodes.invalidRequest);
    final challenge = _store.find(MockCollections.challenges, challengeId);
    if (challenge == null) return MockResponse.error(404, FailureCodes.otpNotFound);
    final now = _clock().toUtc();
    if (!now.isBefore(DateTime.parse(challenge['expiresAt'] as String))) {
      await _store.remove(MockCollections.challenges, challengeId);
      return MockResponse.error(422, FailureCodes.otpExpired);
    }
    final attempts = challenge['attempts'] as int;
    if (attempts >= maxOtpAttempts) return MockResponse.error(429, FailureCodes.otpLocked);
    if (!MockPinVerifier.matches(code, challenge['code'] as String)) {
      await _store.put(MockCollections.challenges, challengeId, {...challenge, 'attempts': attempts + 1});
      return attempts + 1 >= maxOtpAttempts ? MockResponse.error(429, FailureCodes.otpLocked) : MockResponse.error(422, FailureCodes.otpInvalid, field: 'code');
    }
    await _store.remove(MockCollections.challenges, challengeId);
    final phone = challenge['phone'] as String;
    final user = _userByPhone(phone);
    final pinSalt = user?['pinSalt'] as String? ?? base64Encode([for (var index = 0; index < saltLength; index++) _random.nextInt(256)]);
    final registrationToken = IdGenerator.next(bytes: MockAuthenticator.tokenBytes);
    await _store.put(MockCollections.registrations, registrationToken, {'phone': phone, 'pinSalt': pinSalt, 'userId': user?['id'], 'expiresAt': now.add(registrationLifetime).toIso8601String()});
    return MockResponse.ok({'isNewUser': user == null, 'pinSalt': pinSalt, 'registrationToken': registrationToken, 'requiresNic': user?['nic'] != null});
  }

  Map<String, dynamic>? _userByPhone(String phone) {
    for (final user in _store.all(MockCollections.users)) {
      if (user['phone'] == phone) return user;
    }
    return null;
  }

  Future<MockResponse> _register(MockRequest request) async {
    final token = request.body['registrationToken'];
    final registration = _activeRegistration(token);
    if (token is! String || registration == null) return MockResponse.error(401, FailureCodes.registrationInvalid);
    if (registration['userId'] != null) return MockResponse.error(409, FailureCodes.accountExists);
    final pinHash = request.body['pinHash'];
    if (pinHash is! String || pinHash.isEmpty) return MockResponse.error(400, FailureCodes.invalidRequest, field: 'pinHash');
    final device = _validDevice(request.body['device']);
    if (device == null) return MockResponse.error(400, FailureCodes.invalidDeviceKey, field: 'device');
    final userId = IdGenerator.next();
    final phone = registration['phone'] as String;
    await _store.put(MockCollections.users, userId, {'pinAttempts': 0, 'id': userId, 'phone': phone, 'pinHash': pinHash, 'pinSalt': registration['pinSalt'], 'createdAt': _clock().toUtc().toIso8601String()});
    await _store.remove(MockCollections.registrations, token);
    await _securityLog.record(userId, MockSecurityLog.accountCreated, platform: device['platform'] as String);
    return MockResponse.created(await _openSession(userId, phone, device));
  }

  Future<MockResponse> _login(MockRequest request) async {
    final token = request.body['registrationToken'];
    final registration = _activeRegistration(token);
    final userId = registration?['userId'];
    if (token is! String || userId is! String) return MockResponse.error(401, FailureCodes.registrationInvalid);
    if (_store.find(MockCollections.users, userId) == null) return MockResponse.error(401, FailureCodes.registrationInvalid);
    final device = _validDevice(request.body['device']);
    if (device == null) return MockResponse.error(400, FailureCodes.invalidDeviceKey, field: 'device');
    final rejection = await _pinVerifier.verify(userId, request.body['pinHash']);
    if (rejection != null) return rejection;
    final user = _store.find(MockCollections.users, userId)!;
    await _store.remove(MockCollections.registrations, token);
    final isKnownDevice = _store.find(MockCollections.devices, device['id'] as String)?['userId'] == userId;
    await _securityLog.record(userId, isKnownDevice ? MockSecurityLog.signedIn : MockSecurityLog.newDevice, platform: device['platform'] as String);
    return MockResponse.ok(await _openSession(userId, user['phone'] as String, device));
  }

  Future<MockResponse> _resetPin(MockRequest request) async {
    final token = request.body['registrationToken'];
    final registration = _activeRegistration(token);
    final userId = registration?['userId'];
    final user = userId is String ? _store.find(MockCollections.users, userId) : null;
    if (token is! String || userId is! String || user == null) return MockResponse.error(401, FailureCodes.registrationInvalid);
    final pinHash = request.body['pinHash'];
    if (pinHash is! String || pinHash.isEmpty) return MockResponse.error(400, FailureCodes.invalidRequest, field: 'pinHash');
    final device = _validDevice(request.body['device']);
    if (device == null) return MockResponse.error(400, FailureCodes.invalidDeviceKey, field: 'device');
    final storedNic = user['nic'] as String?;
    final nic = request.body['nic'];
    if (storedNic != null && nic is! String) return MockResponse.error(400, FailureCodes.invalidRequest, field: 'nic');
    if (storedNic != null && Nic.tryParse(nic as String)?.number != storedNic) return MockResponse.error(422, FailureCodes.nicMismatch, field: 'nic');
    await _store.put(MockCollections.users, userId, {...user, 'pinAttempts': 0, 'pinHash': pinHash, 'pinLockedUntil': null});
    await _store.remove(MockCollections.registrations, token);
    await _securityLog.record(userId, MockSecurityLog.pinReset, platform: device['platform'] as String);
    return MockResponse.ok(await _openSession(userId, user['phone'] as String, device));
  }

  Future<MockResponse> _changePin(MockRequest request) => _authenticator.guard(request, (principal) async {
    final newPinHash = request.body['newPinHash'];
    if (newPinHash is! String || newPinHash.isEmpty) return MockResponse.error(400, FailureCodes.invalidRequest, field: 'newPinHash');
    final rejection = await _pinVerifier.verify(principal.userId, request.body['pinHash']);
    if (rejection != null) return rejection;
    final user = _store.find(MockCollections.users, principal.userId)!;
    if (MockPinVerifier.matches(newPinHash, user['pinHash'] as String)) return MockResponse.error(422, FailureCodes.pinReused, field: 'newPinHash');
    await _store.put(MockCollections.users, principal.userId, {...user, 'pinHash': newPinHash});
    await _securityLog.record(principal.userId, MockSecurityLog.pinChanged, platform: _store.find(MockCollections.devices, principal.deviceId)?['platform'] as String?);
    return const MockResponse.noContent();
  });

  Map<String, dynamic>? _activeRegistration(Object? token) {
    if (token is! String) return null;
    final registration = _store.find(MockCollections.registrations, token);
    if (registration == null || !_clock().toUtc().isBefore(DateTime.parse(registration['expiresAt'] as String))) return null;
    return registration;
  }

  Map<String, dynamic>? _validDevice(Object? device) {
    if (device is! Map<String, dynamic>) return null;
    final id = device['id'];
    final platform = device['platform'];
    final publicKey = device['publicKey'];
    if (id is! String || id.isEmpty || platform is! String || !_platforms.contains(platform) || publicKey is! String) return null;
    try {
      final bytes = base64Decode(publicKey);
      return bytes.length == publicKeyLength && bytes.first == uncompressedPointPrefix ? device : null;
    } on FormatException {
      return null;
    }
  }

  Future<Map<String, dynamic>> _openSession(String userId, String phone, Map<String, dynamic> device) async {
    final previous = _store.find(MockCollections.devices, device['id'] as String);
    await _authenticator.revokeUser(userId);
    await _authenticator.bindDevice(userId, device, boundAt: previous?['userId'] == userId ? (previous?['boundAt'] as String?) : null);
    return {
      ...await _authenticator.issueSession(userId, device['id'] as String),
      'user': {'id': userId, 'phone': phone},
    };
  }

  Future<MockResponse> _refresh(MockRequest request) async {
    final refreshToken = request.body['refreshToken'];
    if (refreshToken is! String) return MockResponse.error(400, FailureCodes.invalidRequest);
    final session = _authenticator.findSession(refreshToken);
    if (session == null) return MockResponse.error(401, await _authenticator.revokeReusedToken(refreshToken) ? FailureCodes.sessionRevoked : FailureCodes.unauthorized);
    final deviceId = session['deviceId'] as String;
    final rejection = await _authenticator.verifyDevice(request, deviceId);
    if (rejection != null) return rejection;
    final userId = session['userId'] as String;
    final user = _store.find(MockCollections.users, userId);
    if (user == null) return MockResponse.error(401, FailureCodes.unauthorized);
    await _authenticator.retire(refreshToken);
    return MockResponse.ok({
      ...await _authenticator.issueSession(userId, deviceId, family: session['family'] as String),
      'user': {'id': userId, 'phone': user['phone']},
    });
  }

  Future<MockResponse> _logout(MockRequest request) => _authenticator.guard(request, (principal) async {
    await _authenticator.retire(principal.refreshToken);
    return const MockResponse.noContent();
  });

  Future<MockResponse> _unlock(MockRequest request) => _authenticator.guard(request, (principal) async {
    final approval = request.body['approval'];
    final nonce = approval is Map<String, dynamic> ? approval['nonce'] : null;
    final timestamp = approval is Map<String, dynamic> ? approval['timestamp'] : null;
    final replay = await _authenticator.claimNonce(nonce, timestamp);
    if (replay != null) return replay;
    final rejection = await _approvalVerifier.verify(principal, approval, ApprovalPayload.unlock(nonce: nonce as String, timestamp: timestamp as String));
    if (rejection == null) return const MockResponse.noContent();
    if (rejection.errorCode == FailureCodes.pinLocked) await _authenticator.revokeUser(principal.userId);
    return rejection;
  });

  @override
  List<MockRoute> get routes => [
    MockRoute.post(ApiPaths.otp, _requestOtp),
    MockRoute.post(ApiPaths.otpVerify, _verifyOtp),
    MockRoute.post(ApiPaths.register, _register),
    MockRoute.post(ApiPaths.login, _login),
    MockRoute.post(ApiPaths.pinReset, _resetPin),
    MockRoute.post(ApiPaths.pinChange, _changePin),
    MockRoute.post(ApiPaths.refresh, _refresh),
    MockRoute.post(ApiPaths.logout, _logout),
    MockRoute.post(ApiPaths.unlock, _unlock),
  ];
}
