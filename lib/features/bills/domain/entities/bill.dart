import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';
import '../../../payments/domain/entities/recipient.dart';
import 'biller.dart';

class Bill extends Equatable {
  final String accountNumber;
  final String customerName;

  final Biller biller;

  final DateTime dueDate;

  final Money amountDue;

  const Bill({required this.accountNumber, required this.customerName, required this.biller, required this.dueDate, required this.amountDue});

  BillRecipient get recipient => BillRecipient(accountNumber: accountNumber, amountDue: amountDue, billerId: biller.id, billerName: biller.name, category: biller.category, customerName: customerName, dueDate: dueDate);

  @override
  List<Object?> get props => [accountNumber, customerName, biller, dueDate, amountDue];
}
