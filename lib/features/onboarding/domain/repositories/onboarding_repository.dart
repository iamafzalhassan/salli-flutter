abstract interface class OnboardingRepository {
  bool get isComplete;

  Future<void> complete();
}
