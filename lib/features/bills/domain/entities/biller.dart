import 'package:equatable/equatable.dart';

import '../../../../core/utils/pattern_cache.dart';
import '../../../payments/domain/entities/bill_category.dart';
import 'bill_account_kind.dart';

class Biller extends Equatable {
  final String accountHint;
  final String accountPattern;
  final String id;
  final String name;

  final BillAccountKind accountKind;

  final BillCategory category;

  const Biller({required this.accountHint, required this.accountPattern, required this.id, required this.name, required this.accountKind, required this.category});

  bool accepts(String accountNumber) => PatternCache.matches(accountPattern, accountNumber);

  @override
  List<Object?> get props => [accountHint, accountPattern, id, name, accountKind, category];
}
