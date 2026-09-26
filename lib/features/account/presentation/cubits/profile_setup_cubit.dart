import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/errors/result.dart';
import '../../../profile/domain/usecases/get_profile.dart';
import '../../../profile/domain/usecases/update_profile.dart';
import 'profile_setup_state.dart';

class ProfileSetupCubit extends Cubit<ProfileSetupState> {
  static const int minNameLength = 2;

  final GetProfile _getProfile;

  final UpdateProfile _updateProfile;

  ProfileSetupCubit(this._getProfile, this._updateProfile) : super(const ProfileSetupState());

  void dateOfBirthChanged(DateTime dateOfBirth) => emit(state.copyWith(dateOfBirth: () => dateOfBirth, failure: () => null));

  void displayNameChanged(String displayName) => emit(state.copyWith(displayName: displayName, failure: () => null));

  Future<void> load() async {
    final result = await _getProfile();
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => state.copyWith(dateOfBirth: () => value.dateOfBirth, displayName: value.displayName ?? '', isLoading: false),
      Err(:final failure) => state.copyWith(failure: () => failure, isLoading: false),
    });
  }

  Future<void> save() async {
    final displayName = state.displayName.trim();
    if (state.isSaving) return;
    if (displayName.length < minNameLength) {
      emit(state.copyWith(failure: () => const Failure(FailureCodes.invalidName)));
      return;
    }
    emit(state.copyWith(failure: () => null, isSaving: true));
    final result = await _updateProfile(dateOfBirth: state.dateOfBirth, displayName: displayName);
    if (isClosed) return;
    emit(switch (result) {
      Ok() => state.copyWith(isSaved: true, isSaving: false),
      Err(:final failure) => state.copyWith(failure: () => failure, isSaving: false),
    });
  }
}
