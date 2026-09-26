import '../errors/failure_codes.dart';
import '../security/approver.dart';
import 'mock_collections.dart';
import 'mock_pin_verifier.dart';
import 'mock_principal.dart';
import 'mock_response.dart';
import 'mock_signature_verifier.dart';
import 'mock_store.dart';

class MockApprovalVerifier {
  final MockPinVerifier _pinVerifier;

  final MockStore _store;

  const MockApprovalVerifier(this._pinVerifier, this._store);

  Future<MockResponse?> verify(MockPrincipal principal, Object? approval, List<int> payload) async {
    if (approval is! Map<String, dynamic>) return MockResponse.error(400, FailureCodes.invalidRequest, field: 'approval');
    switch (approval['method']) {
      case Approver.pinMethod:
        return _pinVerifier.verify(principal.userId, approval['pinHash']);
      case Approver.biometricMethod:
        final publicKey = _store.find(MockCollections.devices, principal.deviceId)?['biometricKey'] as String?;
        if (publicKey == null) return MockResponse.error(403, FailureCodes.biometricNotEnrolled);
        final signature = approval['signature'];
        if (signature is! String || !MockSignatureVerifier.verify(payload: payload, publicKey: publicKey, signature: signature)) return MockResponse.error(401, FailureCodes.approvalInvalid);
        return null;
      default:
        return MockResponse.error(400, FailureCodes.invalidRequest, field: 'approval');
    }
  }
}
