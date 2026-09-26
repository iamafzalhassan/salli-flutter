import 'package:equatable/equatable.dart';

import 'failure_codes.dart';

class Failure extends Equatable {
  final String code;

  final String? field;

  const Failure(this.code, {this.field});

  const Failure.network() : this(FailureCodes.network);

  const Failure.unknown() : this(FailureCodes.unknown);

  @override
  List<Object?> get props => [code, field];
}
