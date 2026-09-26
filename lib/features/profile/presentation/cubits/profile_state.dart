import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../auth/domain/entities/biometric_status.dart';
import '../../../settings/domain/entities/app_theme_mode.dart';
import '../../domain/entities/profile.dart';

enum ProfileStatus { failure, loading, ready }

class ProfileState extends Equatable {
  final bool isSigningOut;
  final bool isUpdatingBiometrics;

  final AppThemeMode themeMode;

  final BiometricStatus? biometrics;

  final Failure? biometricFailure;
  final Failure? failure;

  final Profile? profile;

  final ProfileStatus status;

  const ProfileState({this.isSigningOut = false, this.isUpdatingBiometrics = false, required this.themeMode, this.biometrics, this.biometricFailure, this.failure, this.profile, this.status = ProfileStatus.loading});

  ProfileState copyWith({
    bool? isSigningOut,
    bool? isUpdatingBiometrics,
    AppThemeMode? themeMode,
    BiometricStatus? Function()? biometrics,
    Failure? Function()? biometricFailure,
    Failure? Function()? failure,
    Profile? Function()? profile,
    ProfileStatus? status,
  }) => ProfileState(
    isSigningOut: isSigningOut ?? this.isSigningOut,
    isUpdatingBiometrics: isUpdatingBiometrics ?? this.isUpdatingBiometrics,
    themeMode: themeMode ?? this.themeMode,
    biometrics: biometrics == null ? this.biometrics : biometrics(),
    biometricFailure: biometricFailure == null ? this.biometricFailure : biometricFailure(),
    failure: failure == null ? this.failure : failure(),
    profile: profile == null ? this.profile : profile(),
    status: status ?? this.status,
  );

  @override
  List<Object?> get props => [isSigningOut, isUpdatingBiometrics, themeMode, biometrics, biometricFailure, failure, profile, status];
}
