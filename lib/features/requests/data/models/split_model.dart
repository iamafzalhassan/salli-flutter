import '../../../../core/utils/money.dart';
import '../../../../core/utils/phone_number.dart';
import '../../../payments/domain/entities/payee.dart';
import '../../domain/entities/bill_split.dart';
import '../../domain/entities/request_status.dart';
import '../../domain/entities/split_share.dart';

class SplitModel {
  final int totalCents;

  final String id;

  final String? note;

  final List<Map<String, dynamic>> shares;

  final DateTime createdAt;

  const SplitModel({required this.totalCents, required this.id, this.note, required this.shares, required this.createdAt});

  factory SplitModel.fromJson(Map<String, dynamic> json) => SplitModel(
    totalCents: json['totalCents'] as int,
    id: json['id'] as String,
    note: json['note'] as String?,
    shares: (json['shares'] as List<dynamic>).cast<Map<String, dynamic>>(),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  BillSplit toEntity() => BillSplit(
    createdAt: createdAt,
    id: id,
    note: note,
    shares: [
      for (final share in shares)
        SplitShare(
          amount: Money(share['amountCents'] as int),
          isSelf: share['isSelf'] as bool,
          payee: share['phone'] == null ? null : Payee(name: share['name'] as String?, phone: PhoneNumber.parse(share['phone'] as String)),
          status: RequestStatus.values.asNameMap()[share['status']] ?? RequestStatus.pending,
        ),
    ],
    total: Money(totalCents),
  );
}
