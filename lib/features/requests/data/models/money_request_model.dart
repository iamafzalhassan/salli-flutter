import '../../../../core/utils/money.dart';
import '../../../../core/utils/phone_number.dart';
import '../../../payments/domain/entities/payee.dart';
import '../../domain/entities/money_request.dart';
import '../../domain/entities/request_direction.dart';
import '../../domain/entities/request_status.dart';

class MoneyRequestModel {
  final int amountCents;

  final String counterpartyPhone;
  final String direction;
  final String id;
  final String status;

  final String? counterpartyName;
  final String? note;
  final String? remindedAt;
  final String? splitId;

  final DateTime createdAt;

  const MoneyRequestModel({
    required this.amountCents,
    required this.counterpartyPhone,
    required this.direction,
    required this.id,
    required this.status,
    this.counterpartyName,
    this.note,
    this.remindedAt,
    this.splitId,
    required this.createdAt,
  });

  factory MoneyRequestModel.fromJson(Map<String, dynamic> json) => MoneyRequestModel(
    amountCents: json['amountCents'] as int,
    counterpartyPhone: json['counterpartyPhone'] as String,
    direction: json['direction'] as String,
    id: json['id'] as String,
    status: json['status'] as String,
    counterpartyName: json['counterpartyName'] as String?,
    note: json['note'] as String?,
    remindedAt: json['remindedAt'] as String?,
    splitId: json['splitId'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  MoneyRequest toEntity() {
    final remindedAt = this.remindedAt;
    return MoneyRequest(
      amount: Money(amountCents),
      counterparty: Payee(name: counterpartyName, phone: PhoneNumber.parse(counterpartyPhone)),
      createdAt: createdAt,
      direction: RequestDirection.values.asNameMap()[direction] ?? RequestDirection.incoming,
      id: id,
      note: note,
      remindedAt: remindedAt == null ? null : DateTime.parse(remindedAt),
      splitId: splitId,
      status: RequestStatus.values.asNameMap()[status] ?? RequestStatus.pending,
    );
  }
}
