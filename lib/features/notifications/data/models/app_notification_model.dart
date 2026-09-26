import '../../../../core/utils/money.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_kind.dart';

class AppNotificationModel {
  static const Map<String, NotificationKind> _kinds = {
    'cashback_earned': NotificationKind.cashbackEarned,
    'kyc_rejected': NotificationKind.kycRejected,
    'kyc_verified': NotificationKind.kycVerified,
    'money_received': NotificationKind.moneyReceived,
    'referral_joined': NotificationKind.referralJoined,
    'request_paid': NotificationKind.requestPaid,
    'request_received': NotificationKind.requestReceived,
    'scratch_card_earned': NotificationKind.scratchCardEarned,
    'welcome': NotificationKind.welcome,
  };

  final bool isRead;

  final String id;
  final String kind;

  final Map<String, dynamic> params;

  final DateTime createdAt;

  const AppNotificationModel({required this.isRead, required this.id, required this.kind, required this.params, required this.createdAt});

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) => AppNotificationModel(
    isRead: json['isRead'] as bool? ?? false,
    id: json['id'] as String,
    kind: json['kind'] as String,
    params: json['params'] as Map<String, dynamic>? ?? const {},
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  AppNotification toEntity() {
    final amountCents = params['amountCents'];
    final name = params['name'] ?? params['merchant'];
    final transactionId = params['transactionId'];
    return AppNotification(
      amount: amountCents is int ? Money(amountCents) : null,
      createdAt: createdAt,
      id: id,
      isRead: isRead,
      kind: _kinds[kind] ?? NotificationKind.other,
      name: name is String ? name : null,
      transactionId: transactionId is String ? transactionId : null,
    );
  }
}
