import '../../../../core/storage/app_preferences.dart';
import '../../domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final AppPreferences _preferences;

  const OnboardingRepositoryImpl(this._preferences);

  @override
  bool get isComplete => _preferences.isOnboardingComplete;

  @override
  Future<void> complete() => _preferences.setOnboardingComplete();
}
