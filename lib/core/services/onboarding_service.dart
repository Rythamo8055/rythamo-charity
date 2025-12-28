import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _onboardingCompleteKey = 'onboarding_complete';

  /// Check if this is the first run of the app
  Future<bool> checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final isComplete = prefs.getBool(_onboardingCompleteKey) ?? false;
    return !isComplete;
  }

  /// Mark onboarding as completed
  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
  }

  /// Reset onboarding state (useful for testing)
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingCompleteKey);
  }
}
