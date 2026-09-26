import '../../../../core/utils/money.dart';
import '../../domain/entities/bill.dart';
import 'biller_model.dart';

class BillModel {
  final int amountDueCents;

  final String accountNumber;
  final String customerName;

  final BillerModel biller;

  final DateTime dueDate;

  const BillModel({required this.amountDueCents, required this.accountNumber, required this.customerName, required this.biller, required this.dueDate});

  factory BillModel.fromJson(Map<String, dynamic> json) => BillModel(
    amountDueCents: json['amountDueCents'] as int,
    accountNumber: json['accountNumber'] as String,
    customerName: json['customerName'] as String,
    biller: BillerModel.fromJson(json['biller'] as Map<String, dynamic>),
    dueDate: DateTime.parse(json['dueDate'] as String),
  );

  Bill toEntity() => Bill(accountNumber: accountNumber, amountDue: Money(amountDueCents), biller: biller.toEntity(), customerName: customerName, dueDate: dueDate);
}
