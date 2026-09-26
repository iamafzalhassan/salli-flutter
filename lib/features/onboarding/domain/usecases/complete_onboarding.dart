import '../repositories/onboarding_repository.dart';

class CompleteOnboarding {
  final OnboardingRepository _repository;

  const CompleteOnboarding(this._repository);

  Future<void> call() => _repository.complete();
}
