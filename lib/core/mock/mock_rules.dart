import '../errors/failure_codes.dart';
import '../network/api_headers.dart';
import 'mock_request.dart';
import 'mock_response.dart';

abstract final class MockRules {
  static const int maxNoteLength = 60;

  static final RegExp phonePattern = RegExp(r'^\+947[0124-8]\d{7}$');

  static MockResponse? rejectAmount(Object? amountCents) => amountCents is! int || amountCents <= 0 ? MockResponse.error(400, FailureCodes.invalidAmount, field: 'amountCents') : null;

  static MockResponse? rejectKey(MockRequest request) {
    final key = request.header(ApiHeaders.idempotencyKey);
    return key == null || key.isEmpty ? MockResponse.error(400, FailureCodes.idempotencyKeyRequired) : null;
  }

  static MockResponse? rejectNote(Object? note) => note != null && (note is! String || note.length > maxNoteLength) ? MockResponse.error(400, FailureCodes.invalidRequest, field: 'note') : null;

  static Map<String, dynamic> receipt(Map<String, dynamic> transaction, {Map<String, dynamic> extra = const {}}) => {
    'amountCents': transaction['amountCents'],
    'feeCents': transaction['feeCents'],
    'id': transaction['id'],
    'note': transaction['note'],
    'reference': transaction['reference'],
    'status': transaction['status'],
    'createdAt': transaction['createdAt'],
    ...extra,
  };
}
