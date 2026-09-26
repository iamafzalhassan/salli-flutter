import '../../domain/entities/security_event.dart';
import '../../domain/entities/security_event_kind.dart';

class SecurityEventModel {
  static const Map<String, SecurityEventKind> _kinds = {
    'account_created': SecurityEventKind.accountCreated,
    'biometrics_disabled': SecurityEventKind.biometricsDisabled,
    'biometrics_enabled': SecurityEventKind.biometricsEnabled,
    'card_frozen': SecurityEventKind.cardFrozen,
    'card_limit_changed': SecurityEventKind.cardLimitChanged,
    'card_unfrozen': SecurityEventKind.cardUnfrozen,
    'new_device': SecurityEventKind.newDevice,
    'pin_changed': SecurityEventKind.pinChanged,
    'pin_reset': SecurityEventKind.pinReset,
    'signed_in': SecurityEventKind.signedIn,
  };

  final String id;
  final String kind;

  final String? platform;

  final DateTime createdAt;

  const SecurityEventModel({required this.id, required this.kind, this.platform, required this.createdAt});

  factory SecurityEventModel.fromJson(Map<String, dynamic> json) => SecurityEventModel(id: json['id'] as String, kind: json['kind'] as String, platform: json['platform'] as String?, createdAt: DateTime.parse(json['createdAt'] as String));

  SecurityEvent toEntity() => SecurityEvent(createdAt: createdAt, id: id, kind: _kinds[kind] ?? SecurityEventKind.other, platform: platform);
}
