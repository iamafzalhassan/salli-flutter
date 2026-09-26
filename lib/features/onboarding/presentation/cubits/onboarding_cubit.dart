import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/complete_onboarding.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  final CompleteOnboarding _completeOnboarding;

  OnboardingCubit(this._completeOnboarding) : super(OnboardingState.inProgress);

  Future<void> complete() async {
    if (state != OnboardingState.inProgress) return;
    emit(OnboardingState.completing);
    await _completeOnboarding();
    if (!isClosed) emit(OnboardingState.completed);
  }
}
