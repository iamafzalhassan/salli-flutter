import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';
import '../../../../core/utils/pattern_cache.dart';

class Bank extends Equatable {
  final bool branchRequired;

  final String accountPattern;
  final String code;
  final String name;
  final String shortName;

  final Money fee;

  const Bank({required this.branchRequired, required this.accountPattern, required this.code, required this.name, required this.shortName, required this.fee});

  bool accepts(String accountNumber) => PatternCache.matches(accountPattern, accountNumber);

  @override
  List<Object?> get props => [branchRequired, accountPattern, code, name, shortName, fee];
}
