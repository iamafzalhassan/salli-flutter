import '../repositories/onboarding_repository.dart';

class CheckOnboardingComplete {
  final OnboardingRepository _repository;

  const CheckOnboardingComplete(this._repository);

  bool call() => _repository.isComplete;
}
