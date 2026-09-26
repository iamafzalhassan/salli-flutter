import '../../../payments/domain/entities/bill_category.dart';
import '../../domain/entities/bill_account_kind.dart';
import '../../domain/entities/biller.dart';

class BillerModel {
  final String accountHint;
  final String accountKind;
  final String accountPattern;
  final String category;
  final String id;
  final String name;

  const BillerModel({required this.accountHint, required this.accountKind, required this.accountPattern, required this.category, required this.id, required this.name});

  factory BillerModel.fromJson(Map<String, dynamic> json) => BillerModel(
    accountHint: json['accountHint'] as String,
    accountKind: json['accountKind'] as String,
    accountPattern: json['accountPattern'] as String,
    category: json['category'] as String,
    id: json['id'] as String,
    name: json['name'] as String,
  );

  Biller toEntity() => Biller(
    accountHint: accountHint,
    accountKind: BillAccountKind.values.asNameMap()[accountKind] ?? BillAccountKind.account,
    accountPattern: accountPattern,
    category: BillCategory.values.asNameMap()[category] ?? BillCategory.other,
    id: id,
    name: name,
  );
}
