import 'dart:convert';

import 'session.dart';

abstract final class SessionCodec {
  static Session fromApi(Map<String, dynamic> json) =>
      Session(accessExpiresAt: DateTime.parse(json['accessExpiresAt'] as String), accessToken: json['accessToken'] as String, refreshToken: json['refreshToken'] as String, userId: (json['user'] as Map<String, dynamic>)['id'] as String);

  static Session? fromStorage(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return Session(accessExpiresAt: DateTime.parse(json['accessExpiresAt'] as String), accessToken: json['accessToken'] as String, refreshToken: json['refreshToken'] as String, userId: json['userId'] as String);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  static String toStorage(Session session) => jsonEncode({'accessToken': session.accessToken, 'refreshToken': session.refreshToken, 'userId': session.userId, 'accessExpiresAt': session.accessExpiresAt.toIso8601String()});
}
