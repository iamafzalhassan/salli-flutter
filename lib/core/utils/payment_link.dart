import 'money.dart';
import 'phone_number.dart';

abstract final class PaymentLink {
  static const int maxNoteLength = 60;

  static const String _amountParameter = 'amount';
  static const String host = 'app';
  static const String _noteParameter = 'note';
  static const String path = '/pay';
  static const String scheme = 'salli';
  static const String _toParameter = 'to';

  static String build({required PhoneNumber phone, Money? amount, String? note}) =>
      Uri(host: host, path: path, queryParameters: {_toParameter: phone.e164, _amountParameter: ?amount?.cents.toString(), _noteParameter: ?note}, scheme: scheme).toString();

  static ({Money? amount, String? note, PhoneNumber phone})? parse(Map<String, String> query) {
    final phone = PhoneNumber.tryParse(query[_toParameter] ?? '');
    if (phone == null) return null;
    final rawAmount = query[_amountParameter];
    final cents = rawAmount == null ? null : int.tryParse(rawAmount);
    if (rawAmount != null && (cents == null || cents <= 0)) return null;
    final note = query[_noteParameter]?.trim();
    return (amount: cents == null ? null : Money(cents), note: note == null || note.isEmpty ? null : (note.length > maxNoteLength ? note.substring(0, maxNoteLength) : note), phone: phone);
  }
}
