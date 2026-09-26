import 'package:equatable/equatable.dart';

import '../../../payments/domain/entities/funding_source_type.dart';
import '../../../payments/domain/entities/recipient.dart';

class FundingSource extends Equatable {
  final String id;
  final String label;
  final String last4;

  final String? bankCode;
  final String? brand;

  final FundingSourceType type;

  const FundingSource({required this.id, required this.label, required this.last4, this.bankCode, this.brand, required this.type});

  TopUpRecipient get topUpRecipient => TopUpRecipient(label: label, last4: last4, sourceId: id, type: type);

  WithdrawalRecipient get withdrawalRecipient => WithdrawalRecipient(label: label, last4: last4, sourceId: id);

  @override
  List<Object?> get props => [id, label, last4, bankCode, brand, type];
}
