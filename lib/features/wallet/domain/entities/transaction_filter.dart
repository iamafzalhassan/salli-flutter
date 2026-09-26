import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';
import 'transaction_type.dart';

class TransactionFilter extends Equatable {
  final String query;

  final Set<TransactionType> types;

  final DateTime? from;
  final DateTime? to;

  final Money? max;
  final Money? min;

  const TransactionFilter({this.query = '', this.types = const {}, this.from, this.to, this.max, this.min});

  bool get hasCriteria => types.isNotEmpty || from != null || to != null || max != null || min != null;
  bool get isEmpty => !hasCriteria && query.trim().isEmpty;

  TransactionFilter copyWith({String? query, Set<TransactionType>? types, DateTime? Function()? from, DateTime? Function()? to, Money? Function()? max, Money? Function()? min}) =>
      TransactionFilter(query: query ?? this.query, types: types ?? this.types, from: from == null ? this.from : from(), to: to == null ? this.to : to(), max: max == null ? this.max : max(), min: min == null ? this.min : min());

  @override
  List<Object?> get props => [query, types, from, to, max, min];
}
