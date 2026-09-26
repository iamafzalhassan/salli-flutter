import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../../auth/domain/usecases/disable_biometrics.dart';
import '../../../auth/domain/usecases/enable_biometrics.dart';
import '../../../auth/domain/usecases/get_biometric_status.dart';
import '../../../auth/domain/usecases/sign_out.dart';
import '../../../settings/domain/entities/app_theme_mode.dart';
import '../../../settings/domain/usecases/get_theme_mode.dart';
import '../../../settings/domain/usecases/save_theme_mode.dart';
import '../../domain/usecases/get_profile.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final DisableBiometrics _disableBiometrics;

  final EnableBiometrics _enableBiometrics;

  final GetBiometricStatus _getBiometricStatus;

  final GetProfile _getProfile;

  final SaveThemeMode _saveThemeMode;

  final SignOut _signOut;

  ProfileCubit(this._disableBiometrics, this._enableBiometrics, this._getBiometricStatus, this._getProfile, GetThemeMode getThemeMode, this._saveThemeMode, this._signOut) : super(ProfileState(themeMode: getThemeMode()));

  Future<void> disableBiometrics() async {
    if (state.isUpdatingBiometrics) return;
    emit(state.copyWith(biometricFailure: () => null, isUpdatingBiometrics: true));
    await _disableBiometrics();
    await _refreshBiometrics();
  }

  Future<void> enableBiometrics(String pin) async {
    if (state.isUpdatingBiometrics) return;
    emit(state.copyWith(biometricFailure: () => null, isUpdatingBiometrics: true));
    final result = await _enableBiometrics(pin);
    if (isClosed) return;
    if (result case Err(:final failure)) emit(state.copyWith(biometricFailure: () => failure));
    await _refreshBiometrics();
  }

  Future<void> load() async {
    if (state.profile == null) emit(state.copyWith(failure: () => null, status: ProfileStatus.loading));
    final (profile, biometrics) = await (_getProfile(), _getBiometricStatus()).wait;
    if (isClosed) return;
    emit(switch (profile) {
      Ok(:final value) => state.copyWith(biometrics: () => biometrics, failure: () => null, profile: () => value, status: ProfileStatus.ready),
      Err(:final failure) => state.copyWith(biometrics: () => biometrics, failure: () => failure, status: state.profile == null ? ProfileStatus.failure : ProfileStatus.ready),
    });
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    await _saveThemeMode(mode);
  }

  Future<void> signOut() async {
    if (state.isSigningOut) return;
    emit(state.copyWith(isSigningOut: true));
    await _signOut();
  }

  Future<void> _refreshBiometrics() async {
    final biometrics = await _getBiometricStatus();
    if (!isClosed) emit(state.copyWith(biometrics: () => biometrics, isUpdatingBiometrics: false));
  }
}
