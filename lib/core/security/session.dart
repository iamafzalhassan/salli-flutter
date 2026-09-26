import 'package:equatable/equatable.dart';

class Session extends Equatable {
  final String accessToken;
  final String refreshToken;
  final String userId;

  final DateTime accessExpiresAt;

  const Session({required this.accessToken, required this.refreshToken, required this.userId, required this.accessExpiresAt});

  bool isAccessExpiredAt(DateTime moment) => !moment.isBefore(accessExpiresAt);

  @override
  List<Object?> get props => [accessToken, refreshToken, userId, accessExpiresAt];
}
