import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../../profile/domain/usecases/get_profile.dart';
import '../../domain/usecases/get_limits.dart';
import '../../domain/usecases/get_verification.dart';
import 'account_state.dart';

class AccountCubit extends Cubit<AccountState> {
  final GetLimits _getLimits;

  final GetProfile _getProfile;

  final GetVerification _getVerification;

  AccountCubit(this._getLimits, this._getProfile, this._getVerification) : super(const AccountState());

  Future<void> load() async {
    final hasContent = state.profile != null;
    if (!hasContent) emit(const AccountState());
    final (limits, profile, verification) = await (_getLimits(), _getProfile(), _getVerification()).wait;
    if (isClosed) return;
    switch ((limits, profile, verification)) {
      case (Ok(value: final limits), Ok(value: final profile), Ok(value: final verification)):
        emit(AccountState(limits: limits, profile: profile, status: AccountStatus.ready, verification: verification));
      case _:
        final failure = [limits, profile, verification].whereType<Err<Object?>>().first.failure;
        emit(AccountState(failure: failure, limits: state.limits, profile: state.profile, status: hasContent ? AccountStatus.ready : AccountStatus.failure, verification: state.verification));
    }
  }
}
