import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../domain/entities/account_limits.dart';
import '../../domain/entities/verification.dart';

enum AccountStatus { failure, loading, ready }

class AccountState extends Equatable {
  final AccountLimits? limits;

  final AccountStatus status;

  final Failure? failure;

  final Profile? profile;

  final Verification? verification;

  const AccountState({this.limits, this.status = AccountStatus.loading, this.failure, this.profile, this.verification});

  @override
  List<Object?> get props => [limits, status, failure, profile, verification];
}
