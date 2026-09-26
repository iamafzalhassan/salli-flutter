import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'lkr_format.dart';
import 'money.dart';

enum LankaQrIssue { checksum, country, currency, format, missingField }

class LankaQrException implements Exception {
  final LankaQrIssue issue;

  const LankaQrException(this.issue);

  @override
  String toString() => 'LankaQrException(${issue.name})';
}

class LankaQr extends Equatable {
  static const int _bitsPerByte = 8;
  static const int _checksumLength = 4;
  static const int _crcInitial = 0xFFFF;
  static const int _crcMask = 0xFFFF;
  static const int _crcPolynomial = 0x1021;
  static const int _crcTopBit = 0x8000;
  static const int _firstAccountTag = 26;
  static const int _hex = 16;
  static const int _lastAccountTag = 51;
  static const int _lengthDigits = 2;
  static const int maxCityLength = 15;
  static const int maxNameLength = 25;
  static const int _tagDigits = 2;

  static const String _accountIdTag = '01';
  static const String _accountTag = '26';
  static const String _additionalDataTag = '62';
  static const String _amountTag = '54';
  static const String _categoryTag = '52';
  static const String _checksumHeader = '6304';
  static const String _cityTag = '60';
  static const String countryCode = 'LK';
  static const String _countryTag = '58';
  static const String currencyCode = '144';
  static const String _currencyTag = '53';
  static const String dynamicInitiation = '12';
  static const String _guidTag = '00';
  static const String _initiationTag = '01';
  static const String merchantGuid = 'lk.lankaqr';
  static const String _nameTag = '59';
  static const String _payloadFormat = '01';
  static const String _payloadFormatTag = '00';
  static const String personalCategory = '0000';
  static const String personalCity = 'Sri Lanka';
  static const String personalGuid = 'lk.salli.p2p';
  static const String _referenceTag = '05';
  static const String staticInitiation = '11';

  static final RegExp _amountPattern = RegExp(r'^\d{1,10}(\.\d{1,2})?$');
  static final RegExp _categoryPattern = RegExp(r'^\d{4}$');
  static final RegExp _twoDigits = RegExp(r'^\d{2}$');

  final bool isDynamic;

  final String accountId;
  final String categoryCode;
  final String city;
  final String guid;
  final String name;

  final String? reference;

  final Money? amount;

  const LankaQr({required this.isDynamic, required this.accountId, required this.categoryCode, required this.city, required this.guid, required this.name, this.reference, this.amount});

  const LankaQr.personal({required String name, required String phone, Money? amount}) : this(isDynamic: amount != null, accountId: phone, categoryCode: personalCategory, city: personalCity, guid: personalGuid, name: name, amount: amount);

  bool get isPersonal => guid == personalGuid;

  String encode() {
    final amount = this.amount;
    final reference = this.reference;
    final body = [
      _field(_payloadFormatTag, _payloadFormat),
      _field(_initiationTag, isDynamic ? dynamicInitiation : staticInitiation),
      _field(_accountTag, '${_field(_guidTag, guid)}${_field(_accountIdTag, accountId)}'),
      _field(_categoryTag, categoryCode),
      _field(_currencyTag, currencyCode),
      if (amount != null) _field(_amountTag, '${amount.rupeePart}.${amount.centPart.toString().padLeft(2, '0')}'),
      _field(_countryTag, countryCode),
      _field(_nameTag, _truncate(name, maxNameLength)),
      _field(_cityTag, _truncate(city, maxCityLength)),
      if (reference != null) _field(_additionalDataTag, _field(_referenceTag, reference)),
      _checksumHeader,
    ].join();
    return '$body${_checksumOf(body)}';
  }

  static LankaQr parse(String payload) {
    final data = payload.trim();
    final checksumAt = data.length - _checksumLength;
    if (checksumAt < _checksumHeader.length || !data.startsWith(_checksumHeader, checksumAt - _checksumHeader.length)) throw const LankaQrException(LankaQrIssue.format);
    if (_checksumOf(data.substring(0, checksumAt)) != data.substring(checksumAt).toUpperCase()) throw const LankaQrException(LankaQrIssue.checksum);
    final fields = _decode(data.substring(0, checksumAt - _checksumHeader.length));
    if (fields.keys.firstOrNull != _payloadFormatTag || fields[_payloadFormatTag] != _payloadFormat) throw const LankaQrException(LankaQrIssue.format);
    final initiation = fields[_initiationTag];
    if (initiation != null && initiation != staticInitiation && initiation != dynamicInitiation) throw const LankaQrException(LankaQrIssue.format);
    final (guid, accountId) = _account(fields);
    if (_required(fields, _currencyTag) != currencyCode) throw const LankaQrException(LankaQrIssue.currency);
    if (_required(fields, _countryTag) != countryCode) throw const LankaQrException(LankaQrIssue.country);
    final categoryCode = _required(fields, _categoryTag);
    if (!_categoryPattern.hasMatch(categoryCode)) throw const LankaQrException(LankaQrIssue.format);
    final rawAmount = fields[_amountTag];
    final additionalData = fields[_additionalDataTag];
    return LankaQr(
      accountId: accountId,
      amount: rawAmount == null ? null : _amountOf(rawAmount),
      categoryCode: categoryCode,
      city: _required(fields, _cityTag),
      guid: guid,
      isDynamic: initiation == dynamicInitiation,
      name: _required(fields, _nameTag),
      reference: additionalData == null ? null : _decode(additionalData)[_referenceTag],
    );
  }

  static int crc16(List<int> bytes) {
    var crc = _crcInitial;
    for (final byte in bytes) {
      crc ^= byte << _bitsPerByte;
      for (var bit = 0; bit < _bitsPerByte; bit++) {
        crc = (crc & _crcTopBit) == 0 ? (crc << 1) & _crcMask : ((crc << 1) ^ _crcPolynomial) & _crcMask;
      }
    }
    return crc;
  }

  static String _field(String tag, String value) => '$tag${value.length.toString().padLeft(_lengthDigits, '0')}$value';

  static String _truncate(String value, int maxLength) => value.length <= maxLength ? value : value.substring(0, maxLength);

  static String _checksumOf(String data) => crc16(utf8.encode(data)).toRadixString(_hex).toUpperCase().padLeft(_checksumLength, '0');

  static (String, String) _account(Map<String, String> fields) {
    for (var tag = _firstAccountTag; tag <= _lastAccountTag; tag++) {
      final template = fields['$tag'];
      if (template == null) continue;
      final account = _decode(template);
      final guid = account[_guidTag]?.toLowerCase();
      final accountId = account[_accountIdTag];
      if ((guid == merchantGuid || guid == personalGuid) && accountId != null && accountId.isNotEmpty) return (guid!, accountId);
    }
    throw const LankaQrException(LankaQrIssue.missingField);
  }

  static Map<String, String> _decode(String data) {
    final fields = <String, String>{};
    var index = 0;
    while (index < data.length) {
      final start = index + _tagDigits + _lengthDigits;
      if (start > data.length) throw const LankaQrException(LankaQrIssue.format);
      final tag = data.substring(index, index + _tagDigits);
      final length = data.substring(index + _tagDigits, start);
      if (!_twoDigits.hasMatch(tag) || !_twoDigits.hasMatch(length) || fields.containsKey(tag)) throw const LankaQrException(LankaQrIssue.format);
      final end = start + int.parse(length);
      if (end > data.length) throw const LankaQrException(LankaQrIssue.format);
      fields[tag] = data.substring(start, end);
      index = end;
    }
    return fields;
  }

  static Money _amountOf(String raw) {
    final amount = _amountPattern.hasMatch(raw) ? LkrFormat.parse(raw) : null;
    if (amount == null || !amount.isPositive) throw const LankaQrException(LankaQrIssue.format);
    return amount;
  }

  static String _required(Map<String, String> fields, String tag) {
    final value = fields[tag];
    if (value == null || value.trim().isEmpty) throw const LankaQrException(LankaQrIssue.missingField);
    return value;
  }

  @override
  List<Object?> get props => [isDynamic, accountId, categoryCode, city, guid, name, reference, amount];
}
