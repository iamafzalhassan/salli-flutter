import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';
import '../../../../core/utils/phone_number.dart';
import 'bill_category.dart';
import 'funding_source_type.dart';
import 'merchant.dart';
import 'payee.dart';

sealed class Recipient extends Equatable {
  const Recipient();

  String get displayName;

  bool get isIncoming => false;

  Money get fee => Money.zero;

  Money? get suggestedAmount => null;
}

final class PersonRecipient extends Recipient {
  final Payee payee;

  const PersonRecipient(this.payee);

  @override
  String get displayName => payee.displayName;

  @override
  List<Object?> get props => [payee];
}

final class MerchantRecipient extends Recipient {
  final String qr;

  final Merchant merchant;

  const MerchantRecipient({required this.qr, required this.merchant});

  @override
  String get displayName => merchant.name;

  @override
  List<Object?> get props => [qr, merchant];
}

final class BillRecipient extends Recipient {
  final String accountNumber;
  final String billerId;
  final String billerName;

  final String? customerName;

  final BillCategory category;

  final DateTime? dueDate;

  final Money? amountDue;

  const BillRecipient({required this.accountNumber, required this.billerId, required this.billerName, this.customerName, required this.category, this.dueDate, this.amountDue});

  @override
  String get displayName => billerName;

  @override
  Money? get suggestedAmount => (amountDue?.isPositive ?? false) ? amountDue : null;

  @override
  List<Object?> get props => [accountNumber, billerId, billerName, customerName, category, dueDate, amountDue];
}

final class ReloadRecipient extends Recipient {
  final String? planId;
  final String? planName;

  final PhoneNumber phone;

  const ReloadRecipient({this.planId, this.planName, required this.phone});

  @override
  String get displayName => phone.display;

  @override
  List<Object?> get props => [planId, planName, phone];
}

final class BankRecipient extends Recipient {
  final String accountName;
  final String accountNumber;
  final String bankCode;
  final String bankName;
  final String bankShortName;

  final String? branchCode;

  @override
  final Money fee;

  const BankRecipient({required this.accountName, required this.accountNumber, required this.bankCode, required this.bankName, required this.bankShortName, this.branchCode, required this.fee});

  @override
  String get displayName => accountName;

  @override
  List<Object?> get props => [accountName, accountNumber, bankCode, bankName, bankShortName, branchCode, fee];
}

final class TopUpRecipient extends Recipient {
  final String label;
  final String last4;
  final String sourceId;

  final FundingSourceType type;

  const TopUpRecipient({required this.label, required this.last4, required this.sourceId, required this.type});

  @override
  bool get isIncoming => true;

  @override
  String get displayName => '$label ••$last4';

  @override
  List<Object?> get props => [label, last4, sourceId, type];
}

final class WithdrawalRecipient extends Recipient {
  final String label;
  final String last4;
  final String sourceId;

  const WithdrawalRecipient({required this.label, required this.last4, required this.sourceId});

  @override
  String get displayName => '$label ••$last4';

  @override
  List<Object?> get props => [label, last4, sourceId];
}
