import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:freerasp/freerasp.dart';

import 'runtime_threat.dart';
import 'session_store.dart';

class RuntimeGuard extends ChangeNotifier {
  static const String _appId = 'com.example.salli';
  static const String _certificateHash = String.fromEnvironment('SALLI_CERT_HASH');
  static const String _teamId = String.fromEnvironment('SALLI_TEAM_ID');
  static const String _watcherMail = String.fromEnvironment('SALLI_SECURITY_MAIL', defaultValue: 'security@salli.lk');

  static const Map<Threat, RuntimeThreat> _threats = {
    Threat.appIntegrity: RuntimeThreat.tampering,
    Threat.debug: RuntimeThreat.debugger,
    Threat.hooks: RuntimeThreat.hooking,
    Threat.privilegedAccess: RuntimeThreat.privilegedAccess,
    Threat.simulator: RuntimeThreat.emulator,
    Threat.unofficialStore: RuntimeThreat.untrustedInstaller,
  };

  static const Set<RuntimeThreat> sessionEndingThreats = {RuntimeThreat.hooking, RuntimeThreat.tampering};

  final Set<RuntimeThreat> _detected = {};

  final SessionStore _sessionStore;

  StreamSubscription<Threat>? _subscription;

  RuntimeGuard(this._sessionStore);

  bool get isCompromised => _detected.isNotEmpty;

  Set<RuntimeThreat> get threats => Set.unmodifiable(_detected);

  Future<void> start() async {
    if (kDebugMode || _subscription != null) return;
    if (_certificateHash.isEmpty || _teamId.isEmpty) {
      detect(RuntimeThreat.unverifiedBuild);
      return;
    }
    _subscription = Talsec.instance.onThreatDetected.listen((threat) {
      final detected = _threats[threat];
      if (detected != null) detect(detected);
    });
    await Talsec.instance.start(
      TalsecConfig(
        androidConfig: AndroidConfig(packageName: _appId, signingCertHashes: const [_certificateHash]),
        iosConfig: IOSConfig(bundleIds: const [_appId], teamId: _teamId),
        isProd: kReleaseMode,
        watcherMail: _watcherMail,
      ),
    );
  }

  void detect(RuntimeThreat threat) {
    if (!_detected.add(threat)) return;
    if (sessionEndingThreats.contains(threat)) unawaited(_sessionStore.clear());
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
