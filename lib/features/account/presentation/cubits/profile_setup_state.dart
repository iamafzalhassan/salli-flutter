import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';

class ProfileSetupState extends Equatable {
  final bool isLoading;
  final bool isSaved;
  final bool isSaving;

  final String displayName;

  final DateTime? dateOfBirth;

  final Failure? failure;

  const ProfileSetupState({this.isLoading = true, this.isSaved = false, this.isSaving = false, this.displayName = '', this.dateOfBirth, this.failure});

  ProfileSetupState copyWith({bool? isLoading, bool? isSaved, bool? isSaving, String? displayName, DateTime? Function()? dateOfBirth, Failure? Function()? failure}) => ProfileSetupState(
    isLoading: isLoading ?? this.isLoading,
    isSaved: isSaved ?? this.isSaved,
    isSaving: isSaving ?? this.isSaving,
    displayName: displayName ?? this.displayName,
    dateOfBirth: dateOfBirth == null ? this.dateOfBirth : dateOfBirth(),
    failure: failure == null ? this.failure : failure(),
  );

  @override
  List<Object?> get props => [isLoading, isSaved, isSaving, displayName, dateOfBirth, failure];
}
